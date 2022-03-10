using System;
using System.Reflection;
using Caliburn.Micro;
using Inprotech.Setup.Pages;

namespace Inprotech.Setup
{
    public class ShellViewModel : Conductor<object>, IShell
    {
        readonly Func<HomeViewModel> _homeViewModel;

        public ShellViewModel( Func<HomeViewModel> homeViewModel)
        {
            if (homeViewModel == null) throw new ArgumentNullException(nameof(homeViewModel));

            _homeViewModel = homeViewModel;
        }

        public override string DisplayName
        {
            get
            {
                var version = Assembly.GetExecutingAssembly().GetName().Version;
                return $"Inprotech Web Applications Setup - {version.Major}.{version.Minor}"; 
            }
            set { }
        }

        protected override void OnActivate()
        {
            base.OnActivate();
            ShowHome();
        }

        public void ShowHome()
        {
            ActivateItem(_homeViewModel());
        }

        public void ShowScreen(IScreen screen)
        {
            ActivateItem(screen);
        }
    }
}