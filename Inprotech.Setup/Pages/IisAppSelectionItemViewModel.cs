using System;
using Caliburn.Micro;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Pages
{
    public class IisAppSelectionItemViewModel : PropertyChangedBase
    {
        public delegate IisAppSelectionItemViewModel Factory(IisAppInfo iisAppInfo);
        readonly IisAppInfo _iisAppInfo;
        bool _isSelected;

        public IisAppSelectionItemViewModel(IisAppInfo iisAppInfo)
        {
            if (iisAppInfo == null) throw new ArgumentNullException(nameof(iisAppInfo));

            _iisAppInfo = iisAppInfo;
        }

        public string DisplayName => $"{_iisAppInfo.Site + _iisAppInfo.VirtualPath} (version={_iisAppInfo.Version})";

        public bool IsEnabled //todo: move to Core
        {
            get
            {
#if DEBUG
                return true;
#else
                return _iisAppInfo.Version >= System.Version.Parse("9.2.6.0");
#endif
            }
        }

        public IisAppInfo IisAppInfo => _iisAppInfo;

        public bool IsSelected
        {
            get => _isSelected;
            set
            {
                _isSelected = value;
                if (_isSelected)
                {
                    NotifyOfPropertyChange(() => IsSelected);
                }
            }
        }
    }
}