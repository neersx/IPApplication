using System;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;
using Caliburn.Micro;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using Newtonsoft.Json;

namespace Inprotech.Setup.Pages
{
    public class SetupRunnerViewModel : Screen, IEventStream
    {
        readonly IShell _shell;
        readonly ISetupWorkflows _setupWorkflows;
        readonly ISetupRunner _setupRunner;
        readonly Func<ISetupAction, ScheduledActionViewModel> _scheduledActionViewModel;

        bool _finished;
        string _title;
        ScheduledActionViewModel _currentAction;

        public SetupRunnerViewModel(
            IShell shell,
            ISetupWorkflows setupWorkflows,
            ISetupRunner setupRunner,
            Func<ISetupAction, ScheduledActionViewModel> scheduledActionViewModel)
        {
            _shell = shell;
            _setupWorkflows = setupWorkflows;
            _setupRunner = setupRunner;
            _scheduledActionViewModel = scheduledActionViewModel;

            Actions = new BindableCollection<ScheduledActionViewModel>();
        }

        public BindableCollection<ScheduledActionViewModel> Actions { get; set; }

        public bool Finished
        {
            get => _finished;
            set
            {
                _finished = value;
                NotifyOfPropertyChange(() => Finished);
            }
        }

        public string Title
        {
            get => _title;
            set
            {
                _title = value;
                NotifyOfPropertyChange(() => Title);
            }
        }

        public void CopyToClipboard()
        {
            var log = from a in Actions
                      select new
                      {
                          a.Description,
                          a.StatusText,
                          a.Events
                      };

            var textLog = JsonConvert.SerializeObject(
                log,
                new JsonSerializerSettings { Formatting = Formatting.Indented });

            Clipboard.SetText(textLog);
        }

        public void Accept()
        {
            _shell.ShowHome();
        }

        public async Task Run()
        {
            SetupWorkflow workflow = null;

            switch (Context.RunMode)
            {
                case SetupRunMode.New:
                    Title = "Install new instance";
                    workflow = _setupWorkflows.New(Constants.DefaultRootPath, Context.SelectedIisApp.Site,
                        Context.SelectedIisApp.VirtualPath, null, null, Context.GetContextSettings(), Context.AuthenticationSettings);
                    break;
                case SetupRunMode.Upgrade:
                    Title = $"Upgrade {Context.SelectedWebApp.InstanceName}";
                    workflow = _setupWorkflows.Upgrade(Context.SelectedWebApp.InstancePath, Constants.DefaultRootPath,
                        null, null, Context.GetContextSettings(), Context.AuthenticationSettings);
                    break;
                case SetupRunMode.Resync:
                    Title = $"Resync {Context.SelectedWebApp.InstanceName}";
                    workflow = _setupWorkflows.Resync(Context.SelectedWebApp.InstancePath, null, null, Context.GetContextSettings());
                    break;
                case SetupRunMode.Remove:
                    Title = $"Remove {Context.SelectedWebApp.InstanceName}";
                    workflow = _setupWorkflows.Remove(Context.SelectedWebApp.InstancePath, null, null, Context.GetContextSettings());
                    break;
                case SetupRunMode.Update:
                    Title = $"Update {Context.SelectedWebApp.InstanceName}";
                    workflow = _setupWorkflows.Update(Context.SelectedWebApp.InstancePath, null, null, Context.GetContextSettings(), Context.AuthenticationSettings);
                    break;
                case SetupRunMode.Resume:
                    Title = $"Resume {Context.SelectedWebApp.InstanceName}";
                    workflow = _setupWorkflows.Resume(Context.SelectedWebApp.InstancePath, null, null, Context.GetContextSettings());
                    break;
            }

            _setupRunner.OnBeforeAction += action =>
            {
                _currentAction = _scheduledActionViewModel(action);
                Actions.Add(_currentAction);
                _currentAction.Status = ActionStatus.InProgress;
            };

            _setupRunner.OnFailed += action =>
            {
                _currentAction.Status = ActionStatus.Failed;
            };

            _setupRunner.OnSuccess += action =>
            {
                if (_currentAction.AllSuccess)
                    _currentAction.Status = ActionStatus.Success;
                else
                    _currentAction.Status = ActionStatus.Warning;
            };

            try
            {
                Finished = false;
                await Task.Run(() => _setupRunner.Run(workflow, this));
            }
            finally
            {
                Finished = true;
            }
        }

        public void Publish(Event actionEvent)
        {
            _currentAction.Events.Add(new EventViewModel { Type = actionEvent.Type, Details = actionEvent.Details });
        }
    }
}