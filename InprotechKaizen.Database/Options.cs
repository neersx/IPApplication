using CommandLine;

namespace InprotechKaizen.Database
{
    public class Options
    {
        [Option('m', "mode", Required = true, HelpText = "The mode of upgrader e.g. inprotech, inprotech integration etc.")]
        public string Mode { get; set; }
        [Option('c', "connectionString", Required = true, HelpText = "The connction string for target database.")]
        public string ConnectionString { get; set; }
        [Option('f', "force", Required = false, DefaultValue = false, HelpText = "Force to run all scripts regardless already added in SchemaVersion table.")]
        public bool Force { get; set; }
        [Option('s', "script", Required = false, DefaultValue = false, HelpText = "Returns the first script that is pending to be executed.")]
        public bool Script { get; set; }
    }
}