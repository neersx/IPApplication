using System;
using System.Linq;
using Caliburn.Micro;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Pages
{
    public class HomeViewModel : Screen
    {
        readonly IShell _shell;
        readonly Func<IisAppSelectionViewModel> _iisAppSelectionViewModel;

        public HomeViewModel(
            IShell shell,
            Func<IisAppSelectionViewModel> iisAppSelectionViewModel,
            PairedWebAppViewModel.Factory pairedInstanceViewModel,
            IService service)
        {
            _shell = shell;
            _iisAppSelectionViewModel = iisAppSelectionViewModel;

            var webApps = service.FindAllWebApps();

            PairedInstances = new BindableCollection<PairedWebAppViewModel>(webApps.Select(_ => pairedInstanceViewModel(_)));

            Context.Reset();
        }

        public BindableCollection<PairedWebAppViewModel> PairedInstances { get; private set; }

        public void ShowInprotechInstanceSelection()
        {            
            Context.RunMode = SetupRunMode.New;

            _shell.ShowScreen(_iisAppSelectionViewModel());
        }

        public bool HasNoInstance => PairedInstances.Count == 0;
    }
}