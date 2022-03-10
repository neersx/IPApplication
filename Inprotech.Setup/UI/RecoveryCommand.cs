using System;
using System.Threading.Tasks;
using System.Windows.Input;
using System.Windows.Threading;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.UI
{
    public class RecoveryCommand : ICommand, IEventStream
    {
        readonly IMessageBox _messageBox;
        readonly IRecoveryManager _recoveryManager;
        readonly IService _service;
        readonly ISetupRunner _setupRunner;
        readonly ISetupWorkflows _setupWorkflows;
        bool _running;

        public RecoveryCommand(ISetupWorkflows setupWorkflows,
                               ISetupRunner setupRunner,
                               IMessageBox messageBox,
                               IService service,
                               IRecoveryManager recoverManager)
        {
            _setupWorkflows = setupWorkflows;
            _setupRunner = setupRunner;
            _messageBox = messageBox;
            _service = service;
            _recoveryManager = recoverManager;
            RegisterFailedEvent();
        }

        public string Content => "View options to resolve";

#pragma warning disable 0067
        public event EventHandler CanExecuteChanged;
#pragma warning restore 0067

        public bool CanExecute(object parameter)
        {
            return !_running;
        }

        public void Execute(object parameter)
        {
            var failedActionName = Convert.ToString(parameter);
            _running = true;

            RunSetupWorkflow(
                             workflows => 
                                 workflows.Recovery(SelectedWebApp.InstancePath, failedActionName, null, null, Context.GetContextSettings()));
        }

        public void Publish(Event actionEvent)
        {
        }

        public bool IsSupported(string actionName)
        {
            return _recoveryManager.CanRecover(SelectedWebApp.InstancePath, actionName);
        }

        void RunSetupWorkflow(Func<ISetupWorkflows, SetupWorkflow> createWorkflow)
        {
            var workflow = createWorkflow(_setupWorkflows);
            Task.Run(() =>
                     {
                         _setupRunner.Run(workflow, this);
                         _running = false;
                     });
        }

        void RegisterFailedEvent()
        {
            _setupRunner.OnFailed += action => { Dispatcher.CurrentDispatcher.Invoke(() => { _messageBox.Alert("Failed to retrieve the options to resolve.", "Error"); }); };
        }

        WebAppInfoWrapper SelectedWebApp => Context.SelectedWebApp ?? 
            (Context.SelectedWebApp = _service.FindWebApp(Context.SelectedIisApp));
    }
}