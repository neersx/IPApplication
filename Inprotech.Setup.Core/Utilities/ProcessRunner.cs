namespace Inprotech.Setup.Core.Utilities
{
    public interface IProcessRunner
    {
        CommandLineUtilityResult Run(string path, string args, int timeToLiveMilliseconds = -1);

        void Open(string path);
    }

    public class ProcessRunner : IProcessRunner
    {
        public CommandLineUtilityResult Run(string path, string args, int timeToLiveMilliseconds = -1)
        {
            return CommandLineUtility.Run(path, args, timeToLiveMilliseconds);
        }

        public void Open(string path)
        {
            System.Diagnostics.Process.Start(path);
        }
    }
}
