using System.Diagnostics;
using System.Threading.Tasks;

namespace Inprotech.Setup.Core.Utilities
{
    public static class CommandLineUtility
    {
        public static CommandLineUtilityResult Run(string path, string args, int timeToLiveMilliseconds = -1)
        {
            return RunAndWait(BuildProcessStartInfo(path, args), timeToLiveMilliseconds);
        }

        public static async Task<CommandLineUtilityResult> RunAsync(string path, string args, int timeToLiveMilliseconds = -1)
        {
            return await Run(BuildProcessStartInfo(path, args), timeToLiveMilliseconds);
        }

        public static CommandLineUtilityResult RunAs(
            string path,
            string args,
            string username,
            string password,
            int timeToLiveMilliseconds = -1)
        {
            return RunAndWait(BuildProcessStartInfo(path, args).RunAs(username, password), timeToLiveMilliseconds);
        }

        public static string EncodeArgument(string value)
        {
            return value.Replace("\"", "\\\"");
        }

        static CommandLineUtilityResult RunAndWait(ProcessStartInfo processStartInfo, int timeToLiveMilliseconds)
        {
            var p = Process.Start(processStartInfo);

            var ses = p.StandardError.ReadToEndAsync();
            var sos = p.StandardOutput.ReadToEndAsync();

            if(!p.WaitForExit(timeToLiveMilliseconds))
            {
                p.Kill();
            }

// ReSharper disable once CoVariantArrayConversion
            Task.WaitAll(new[] {ses, sos});

            return new CommandLineUtilityResult {ExitCode = p.ExitCode, Error = ses.Result, Output = sos.Result};
        }

        static async Task<CommandLineUtilityResult> Run(ProcessStartInfo processStartInfo, int timeToLiveMilliseconds)
        {
            var p = Process.Start(processStartInfo);

            var ses = await p.StandardError.ReadToEndAsync();
            var sos = await p.StandardOutput.ReadToEndAsync();

            if (!p.WaitForExit(timeToLiveMilliseconds))
            {
                p.Kill();
            }

            return new CommandLineUtilityResult { ExitCode = p.ExitCode, Error = ses, Output = sos };
        }

        static ProcessStartInfo BuildProcessStartInfo(string path, string args)
        {
            return new ProcessStartInfo(path, args)
                   {
                       UseShellExecute = false,
                       RedirectStandardOutput = true,
                       RedirectStandardError = true,
                       CreateNoWindow = true,
                       WindowStyle = ProcessWindowStyle.Hidden,
                   };
        }
    }
}