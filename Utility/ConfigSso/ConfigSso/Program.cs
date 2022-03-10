using System;
using System.IO;
using System.Linq;

namespace Inprotech.Utility.ConfigSso
{
    /// <summary>
    ///     This utility is used to modify the target for Ip Platform.
    ///     It makes it easier for CPA users to switch between different IP Platforrm environments.
    ///     Following app settings can be changed using this script.
    ///     --SSO Environment (Staging, Pre-Production, Demo, Production)----Required
    /// </summary>
    internal class Program
    {
        private const string ContentPath = @"CPA Global\Inprotech Web Applications\Content";

        private const string ExitMessage = "Press any key to exit.";
        
        private static void Main()
        {
            var basePath = Directory.GetCurrentDirectory().Contains("Inprotech Web Applications")
                ? Path.Combine(Directory.GetCurrentDirectory(), "Content")
                : Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86),
                    ContentPath);

            var c1 = Path.Combine(basePath, "Inprotech.Server", "Inprotech.Server.exe.config");
            var c2 = Path.Combine(basePath, "Inprotech.IntegrationServer", "Inprotech.IntegrationServer.exe.config");

            if (!File.Exists(c1) || !File.Exists(c2))
            {
                Console.WriteLine("Unable to resolve where 'Inprotech Web Application' has been installed");
                Console.WriteLine("This Utility can only be run from the following locations:");
                Console.WriteLine("   * Anywhere, if IWA is installed to the default location");
                Console.WriteLine("   * IWA installed folder (where the folder name is 'Inprotech Web Applications'");
                Console.WriteLine(ExitMessage);
                Console.ReadKey();
                return;
            }

            Console.WriteLine("To continue using this Utility, you must accept that ");
            Console.WriteLine("1. This tool can only be used by CPA Global employee.");
            Console.WriteLine(
                "2. This tool can only be applied to a CPA Global's system, e.g. CPA Global laptop or CPA Global development environment.");
            Console.WriteLine("Press any key to continue, or [ESC] to exit.");

            if (Console.ReadKey().Key == ConsoleKey.Escape)
                return;

            var env = SelectOption();
            if (env == null) return;
            Console.Clear();

            Console.WriteLine($"Changing IP Platform to target {env} Environment");

            Tools.SetEnvironment(c1, env.Value, path => Console.WriteLine($"{path} updated."), error => throw new Exception(error));
            Tools.SetEnvironment(c2, env.Value, path => Console.WriteLine($"{path} updated."), error => throw new Exception(error));

            Console.WriteLine();
            Console.WriteLine(
                "You must remove any existing 'Paired Instance', then 'Create Instance' for the settings to take effect.");
            Console.WriteLine();
            Console.WriteLine(ExitMessage);

            Console.ReadKey();
        }

        private static Tools.EnvironmentType? SelectOption()
        {
            Console.WriteLine("Which Environment do you want for The IP Platform");
            foreach (var environmentType in Enum.GetValues(typeof(Tools.EnvironmentType)).Cast<Tools.EnvironmentType>())
                Console.WriteLine($"Press {(int)environmentType} for {environmentType}");
            Console.WriteLine("Press any other key to exit");
            var key = Console.ReadKey();
            if (Enum.TryParse(key.KeyChar.ToString(), true, out Tools.EnvironmentType res))
                return res;
            return null;
        }
    }
}