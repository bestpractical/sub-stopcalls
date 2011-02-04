#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef struct {
    U16 length;
    U16 max;
    OP* ops[];
} oplist;

#define new_oplist(l) l = (oplist*) malloc(sizeof(U16)*2 + 16*sizeof(OP*)); \
    l->length = 0; l->max = 16;

static void
pushop(oplist* list, OP* op)
{
    if (!op) return;
    if (list->length >= list->max) {
        realloc(list, list->max*2);
        list->max *= 2;
    }
    list->ops[ list->length++ ] = op;
}

static int
is_in_oplist(oplist* list, OP* op) {
    U16 i;
    if (list->length == 0)
        return 0;

    for ( i = 0; i < list->length; i++ ) {
        if ( op == list->ops[i] )
            return 1;
    }
    return 0;
}

typedef struct {
    const PERL_CONTEXT* cx;
    OP* enter;
    OP* sibling;
    OP* parent;
    oplist* targets;
    oplist* prev;
} call_info;

static OP*
find_entry(pTHX_ OP* start_at, OP* retop, OP** sibling, OP** parent )
{
    OP *o, *p, *res;
    for (o = start_at; o; p = o, o = o->op_sibling) {
        if ( o == retop ) {
            return NULL;
        }
        /* o->op_next on entersub is a retop */
        else if (o->op_type == OP_ENTERSUB && o->op_next == retop) {
            if (sibling && p) *sibling = p;
            return o;
        }

        if (o->op_flags & OPf_KIDS) {
            res = find_entry(cUNOPo->op_first, retop, sibling, parent);
            if (res) {
                if ( sibling && !*sibling && parent && !*parent )
                    *parent = o;
                return res;
            }
        }
    }
    return NULL;
}

static void
_tree2oplist(pTHX_ oplist* dst, OP* start_at)
{
    OP *o;
    pushop(dst, start_at);
    if (!(start_at->op_flags & OPf_KIDS)) return;

    for (o = cUNOPx(start_at)->op_first; o; o = o->op_sibling) {
        _tree2oplist(dst, o);
    }
}

static oplist*
tree2oplist(pTHX_ OP* start_at)
{
    oplist *res;
    new_oplist(res);
    _tree2oplist(res, start_at);
    return res;
}


static void
_find_prev_ops(pTHX_ oplist* res, OP* start_at, oplist* into, OP* stop_at )
{
    OP *o; U16 i;

    for (o = start_at; o; o = o->op_sibling) {
        if ( o == stop_at )
            return;

        if ( is_in_oplist( into, o ) )
            continue;

        if ( is_in_oplist( into, o->op_next ) )
            pushop(res, o);

        if (o->op_flags & OPf_KIDS) {
            _find_prev_ops(res, cUNOPo->op_first, into, stop_at);
        }
    }
}

static oplist*
find_prev_ops(pTHX_ OP* start_at, oplist* into, OP* stop_at )
{
    oplist *res;

    new_oplist(res);
    _find_prev_ops(aTHX_ res, start_at, into, stop_at);
    if ( res->length ) return res;

    free(res);
    return NULL;
}

static call_info
caller_info(pTHX)
{
    call_info res;
    const PERL_CONTEXT *cx = Perl_caller_cx(0, NULL);
    res.cx = cx;

    res.sibling = NULL;
    res.parent = NULL;
    res.enter = find_entry( aTHX_ cx->blk_oldcop, cx->blk_sub.retop, &res.sibling, &res.parent );
    res.targets = tree2oplist(aTHX_ res.enter);
    res.prev = find_prev_ops(aTHX_ cx->blk_oldcop, res.targets, cx->blk_sub.retop);

    return res;
}

void
void_case(pTHX_ call_info* info) {
    int i;
    for( i = 0; i < info->prev->length; i++ ) {
        info->prev->ops[i]->op_next = info->enter->op_next;
    }
    if ( info->sibling ) {
        info->sibling->op_sibling = info->enter->op_sibling;
    }
}

static void
no_more_calls(pTHX)
{
    call_info info = caller_info(aTHX);
    switch( info.cx->blk_gimme ) {
        case G_ARRAY:
            break;
        case G_SCALAR:
            break;
        case G_VOID:
            void_case( &info );
    }
}
MODULE = No::Calls   PACKAGE = No::Calls

PROTOTYPES: DISABLE


void
no_more_calls()
    C_ARGS:
    aTHX
