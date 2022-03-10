using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Threading;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Actions;

namespace Inprotech.Setup.Actions
{
    public class FailedCleanUpInstance : ISetupActionAsync
    {
        public string Description { get; } = "Failed Cleanup";
        public bool ContinueOnException { get; } = false;
        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            RunAsync(context, eventStream).Wait();
        }

        public async Task RunAsync(IDictionary<string, object> context, IEventStream eventStream)
        {
            var message = "Setup completed successfully. You can safely proceed to Finish the setup.";
            var title = "Cleanup Completed successfully";
            try
            {
                await new CleanUpInstance(new FileSystem(), new InprotechServerPersistingConfigManager())
                {
                    MaxRetries = 0
                }.RunAsync(context, new NullEventStream());
            }
            catch (UnauthorizedAccessException e)
            {
                title = "Cleanup Error";
                message = $"The file below is in use. Close the process accessing this file or restart the system and try again.\n\n{e.Message}\n{e.InnerException?.Message}";
            }
            catch (Exception e)
            {
                title = "Cleanup Error";
                message = $"The file cleanup failed. Resolve the error to continue.\n\n{e.Message}\n{e.InnerException?.Message}";
            }

            ShowMessage(context, title, message);
        }

        void ShowMessage(IDictionary<string, object> context, string title, string message)
        {
            if (context.ContainsKey("Dispatcher"))
            {
                var dispatcher = (Dispatcher)context["Dispatcher"];

                dispatcher.Invoke(() =>
                {
                    MessageBox.Show(message, title, MessageBoxButton.OK, MessageBoxImage.Information);
                });
            }
        }
    }
}
