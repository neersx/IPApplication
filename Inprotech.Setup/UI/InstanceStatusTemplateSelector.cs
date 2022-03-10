using System.Windows;
using System.Windows.Controls;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.UI
{
    public class InstanceStatusTemplateSelector : DataTemplateSelector
    {
        public DataTemplate Online { get; set; }

        public DataTemplate Offline { get; set; }

        public override DataTemplate SelectTemplate(object item, DependencyObject container)
        {
            var template = Online;

            if ((ServiceStatus) item == ServiceStatus.Offline)
            {
                template = Offline;
            }

            return template;
        }
    }
}