using System;
using System.ComponentModel;
using System.Linq;
using Caliburn.Micro;

namespace Inprotech.Setup.Pages
{
    public class IisAppSelectionViewModel : Screen
    {
        readonly IShell _shell;
        readonly Func<IisAppDetailsViewModel> _iisAppDetailsViewModel;
        readonly IService _service;
        readonly IisAppSelectionItemViewModel.Factory _iisAppSelectionItemViewModel;
        IisAppSelectionItemViewModel _selectedIisApp;
        
        public IisAppSelectionViewModel(IShell shell,
            Func<IisAppDetailsViewModel> iisAppDetailsViewModel,
            IService service, 
            IisAppSelectionItemViewModel.Factory iisAppSelectionItemViewModel)
        {
            _shell = shell;
            _iisAppDetailsViewModel = iisAppDetailsViewModel;
            _service = service;
            _iisAppSelectionItemViewModel = iisAppSelectionItemViewModel;

            InitialiseAvailableInstances();
        }        

        public BindableCollection<IisAppSelectionItemViewModel> AvailableInstances { get; private set; }

        public bool IsNextEnabled
        {
            get; private set;
        }

        public bool HasNoInstance => !HasInstance;

        public bool HasInstance => AvailableInstances.Count != 0;

        public void Cancel()
        {
            _shell.ShowHome();
        }

        public void Next()
        {
            var next = _iisAppDetailsViewModel();

            Context.SelectedIisApp = _selectedIisApp.IisAppInfo;

            _shell.ShowScreen(next);
        }

        void InitialiseAvailableInstances()
        {
            var iisApps = _service.FindAllUnpairedIisApps();

            AvailableInstances =
                new BindableCollection<IisAppSelectionItemViewModel>(
                    iisApps.Select(_ => _iisAppSelectionItemViewModel(_)));

            foreach (var instance in AvailableInstances)
            {
                instance.PropertyChanged += OnInstanceOnPropertyChanged;
            }
        }

        void OnInstanceOnPropertyChanged(object sender, PropertyChangedEventArgs args)
        {
            if (args.PropertyName != "IsSelected") return;

            _selectedIisApp = sender as IisAppSelectionItemViewModel;
            if (_selectedIisApp == null) return;

            IsNextEnabled = true;
            NotifyOfPropertyChange(() => IsNextEnabled);
        }
    }
}
