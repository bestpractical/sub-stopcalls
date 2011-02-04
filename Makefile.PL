use inc::Module::Install;
all_from 'lib/Sub/StopCalls.pm';
makemaker_args( OPTIMIZE => '-g' );
WriteAll();
