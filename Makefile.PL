use inc::Module::Install;
all_from 'lib/No/Calls.pm';
makemaker_args( OPTIMIZE => '-g' );
WriteAll();
