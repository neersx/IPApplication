using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Threading.Tasks;

namespace Inprotech.Tests.Integration.Utils._7z
{
    public static class SevenZipHelper
    {
        static readonly string BasePath =
            Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) ?? Path.GetFullPath(".");

        public static void ExtractToDirectory(string archive, string destinationDirectory)
        {
            RunnerInterface.Log($"Unpacking {archive}: to {destinationDirectory}");

            var fileName = Path.Combine(BasePath, "Utils", "7z", "7za.exe");
            var command = $"x \"{archive}\" -y -o\"{destinationDirectory}\"";

            using (var p = Process.Start(new ProcessStartInfo
            {
                UseShellExecute = false,
                WindowStyle = ProcessWindowStyle.Hidden,
                RedirectStandardError = true,
                RedirectStandardOutput = true,
                FileName = fileName,
                Arguments = command
            }))
            {
                if (p == null) throw new Exception("Process could not be created!");

                var error = p.StandardError.ReadToEndAsync();
                var output = p.StandardOutput.ReadToEndAsync();

                if (!p.WaitForExit(600000)) /* 10 minutes */
                {
                    p.Kill();
                }

                Task.WaitAll(error, output);

                RunnerInterface.Log(output.Result);
                RunnerInterface.Log(error.Result);
            }
        }
    }
}