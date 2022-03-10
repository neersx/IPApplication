using System;
using System.IO;
using System.Linq;
using CommandLine;
using CommandLine.Text;
using Inprotech.Utility.ConfigSso;

namespace ConfigSsoCli
{
    class Program
    {
        static int Main(string[] args)
        {
            if (!args.Any())
            {
                args = new[] {"--help"};
            }

            var options = new Options();
            if (!Parser.Default.ParseArgumentsStrict(args, options, () => ShowHelp(options)))
            {
                return -1;
            }

            return Configure(options);
        }

        static int Configure(Options options)
        {
            var c1 = Path.Combine(options.Path, "Content", "Inprotech.Server", "Inprotech.Server.exe.config");
            var c2 = Path.Combine(options.Path, "Content", "Inprotech.IntegrationServer", "Inprotech.IntegrationServer.exe.config");

            if (!File.Exists(c1) || !File.Exists(c2))
            {
                Console.WriteLine("Unable to resolve where 'Inprotech Web Application' has been installed");
                return -1;
            }

            Console.WriteLine($"Changing IP Platform to target {options.Environment} Environment");

            Tools.SetEnvironment(c1, options.Environment, path => Console.WriteLine($"{path} updated."), error => throw new Exception(error));
            Tools.SetEnvironment(c2, options.Environment, path => Console.WriteLine($"{path} updated."), error => throw new Exception(error));

            Console.WriteLine("You must remove any existing 'Paired Instance', then 'Create Instance' for the settings to take effect.");
            Console.WriteLine("Done.");

            return 0;
        }

        static void ShowHelp(Options options)
        {
            Console.WriteLine(options.GetUsage());
        }
    }

    internal class Options
    {
        [Option("path", Required = true, HelpText = "Installation Root for IWA")]
        public string Path { get; set; }

        [Option("env", Required = true, HelpText = "Environment")]
        public Tools.EnvironmentType Environment { get; set; }

        [HelpOption]
        public string GetUsage()
        {
            return HelpText.AutoBuild(this, helpText => HelpText.DefaultParsingErrorsHandler(this, helpText));
        }
    }
}
