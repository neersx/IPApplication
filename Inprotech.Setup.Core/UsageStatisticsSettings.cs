using System.ComponentModel;
using System.Runtime.CompilerServices;
using Inprotech.Setup.Core.Annotations;

namespace Inprotech.Setup.Core
{
    public class UsageStatisticsSettings : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged;

        [NotifyPropertyChangedInvocator]
        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        bool? _userUsageStatisticsConsented;
        bool? _firmUsageStatisticsConsented;
        public bool? UserUsageStatisticsConsented
        {
            get => _userUsageStatisticsConsented;
            set
            {
                if(value == _userUsageStatisticsConsented) return;
                _userUsageStatisticsConsented = value;
                OnPropertyChanged(nameof(UserUsageStatisticsConsented));
            }
        }
        public bool? FirmUsageStatisticsConsented
        {
            get => _firmUsageStatisticsConsented;
            set
            {
                if(value == _firmUsageStatisticsConsented) return;
                _firmUsageStatisticsConsented = value;
                OnPropertyChanged(nameof(FirmUsageStatisticsConsented));
            }
        }

        public void Reset()
        {
            FirmUsageStatisticsConsented = null;
            UserUsageStatisticsConsented = null;
        }
    }
}