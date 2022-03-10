using System.Linq;
using Caliburn.Micro;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using Inprotech.Setup.UI;

namespace Inprotech.Setup.Pages
{
    public class ScheduledActionViewModel : PropertyChangedBase
    {
        readonly ISetupAction _setupAction;
        ActionStatus _status;

        public ScheduledActionViewModel(ISetupAction setupAction, RecoveryCommand recoveryCommand)
        {
            _setupAction = setupAction;
            RecoveryCommand = recoveryCommand;

            Events = new BindableCollection<EventViewModel>();
        }

        public string Description => _setupAction.Description;

        public BindableCollection<EventViewModel> Events { get; set; }

        public bool AllSuccess
        {
            get { return Events.All(e => e.Type == EventType.Information); }
        }

        public ActionStatus Status
        {
            get => _status;
            set
            {
                _status = value;
                NotifyOfPropertyChange(() => Status);
                NotifyOfPropertyChange(() => StatusText);
                NotifyOfPropertyChange(() => ErrorVisible);
                NotifyOfPropertyChange(() => FailedActionName);
            }
        }

        public string StatusText
        {
            get
            {
                switch (Status)
                {
                    case ActionStatus.Ready:
                        return "Pending";
                    case ActionStatus.InProgress:
                        return "Running";
                    case ActionStatus.Success:
                        return "Success";
                    case ActionStatus.Warning:
                        return "Warning";
                    case ActionStatus.Failed:
                        return "Failed";
                }

                return string.Empty;
            }
        }

        public bool ErrorVisible => Status == ActionStatus.Failed &&
                                    IsRecoveryAvailable &&
                                    RecoveryCommand.IsSupported(FailedActionName);

        public string FailedActionName => Status == ActionStatus.Failed ? _setupAction.GetType().Name : string.Empty;

        public RecoveryCommand RecoveryCommand { get; private set; }

        bool IsRecoveryAvailable => Context.RunMode == SetupRunMode.New || Context.SelectedWebApp.Features.Contains("failed-action-recovery");
    }
}