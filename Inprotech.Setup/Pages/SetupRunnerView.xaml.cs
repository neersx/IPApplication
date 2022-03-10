using System.Collections.Specialized;
using System.Windows;

namespace Inprotech.Setup.Pages
{    
    public partial class SetupRunnerView 
    {
        public SetupRunnerView()
        {
            InitializeComponent();
            Loaded += SetupRunnerView_Loaded;
        }

        void SetupRunnerView_Loaded(object sender, RoutedEventArgs e)
        {
            var vm = Actions.DataContext as SetupRunnerViewModel;
            if(vm == null) return;

            vm.Actions.CollectionChanged += ActionsOnCollectionChanged;
        }

        void ActionsOnCollectionChanged(object sender, NotifyCollectionChangedEventArgs notifyCollectionChangedEventArgs)
        {
            ActionsScroll.ScrollToBottom();
        }
    }
}
