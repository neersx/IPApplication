using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using Caliburn.Micro;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Pages
{
    public class AuthenticationModesViewModel : Screen, INotifyDataErrorInfo
    {
        readonly Dictionary<string, ICollection<string>> _validationErrors = new Dictionary<string, ICollection<string>>();

        bool _authForms = true;
        bool _authWindows;
        bool _authCpaSso;
        bool _authAdfs;
        bool _internal2FA;
        bool _external2FA;

        public string AuthenticationMode
        {
            get
            {
                var tokens = new List<string>();
                if (AuthForms)
                {
                    tokens.Add(Constants.AuthenticationModeKeys.Forms);
                }
                if (AuthWindows)
                {
                    tokens.Add(Constants.AuthenticationModeKeys.Windows);
                }
                if (AuthCpaSso)
                {
                    tokens.Add(Constants.AuthenticationModeKeys.Sso);
                }
                if (AuthAdfs)
                {
                    tokens.Add(Constants.AuthenticationModeKeys.Adfs);
                }

                var authMode = string.Join(",", tokens);
                Context.SetAuthMode(authMode);
                return authMode;
            }
        }

        public string Authentication2FAMode
        {
            get
            {
                var tokens = new List<string>();
                if (Internal2FA)
                {
                    tokens.Add(Constants.Authentication2FAModeKeys.Internal);
                }
                if (External2FA)
                {
                    tokens.Add(Constants.Authentication2FAModeKeys.External);
                }

                var authMode = string.Join(",", tokens);
                Context.Set2FAMode(authMode);
                return authMode;
            }
        }

        public bool AuthForms
        {
            get => _authForms;
            set
            {
                _authForms = value;
                if (!value)
                {
                    Internal2FA = false;
                    External2FA = false;
                    NotifyOfPropertyChange(() => Internal2FA);
                    NotifyOfPropertyChange(() => External2FA);
                }
                SetErrors(nameof(AuthenticationMode), null);
                NotifyOfPropertyChange(() => Authentication2FAMode);
                NotifyOfPropertyChange(() => AuthenticationMode);
            }
        }

        public bool Internal2FA
        {
            get => _internal2FA;
            set
            {
                _internal2FA = value;
                if(value)
                {
                    AuthForms = true;
                    NotifyOfPropertyChange(() => AuthForms);
                }
                SetErrors(nameof(Authentication2FAMode), null);
                NotifyOfPropertyChange(() => Authentication2FAMode);
                NotifyOfPropertyChange(() => AuthenticationMode);
            }
        }

        public bool External2FA
        {
            get => _external2FA;
            set
            {
                _external2FA = value;
                if(value)
                {
                    AuthForms = true;
                    NotifyOfPropertyChange(() => AuthForms);
                }
                SetErrors(nameof(Authentication2FAMode), null);
                NotifyOfPropertyChange(() => Authentication2FAMode);
                NotifyOfPropertyChange(() => AuthenticationMode);
            }
        }

        public bool AuthWindows
        {
            get => _authWindows;
            set
            {
                _authWindows = value;
                if (!value)
                {
                    AuthAdfs = false;
                }
                SetErrors(nameof(AuthenticationMode), null);
                NotifyOfPropertyChange(() => Authentication2FAMode);
                NotifyOfPropertyChange(() => AuthenticationMode);
                NotifyOfPropertyChange(() => AuthWindows);
            }
        }

        public bool AuthCpaSso
        {
            get => _authCpaSso;
            set
            {
                _authCpaSso = value;
                SetErrors(nameof(AuthenticationMode), null);
                NotifyOfPropertyChange(() => Authentication2FAMode);
                NotifyOfPropertyChange(() => AuthenticationMode);
            }
        }

        public bool AuthAdfs
        {
            get => _authAdfs;
            set
            {
                _authAdfs = value;
                if (_authAdfs)
                {
                    AuthWindows = true;
                }
                SetErrors(nameof(AuthenticationMode), null);
                NotifyOfPropertyChange(() => AuthenticationMode);
                NotifyOfPropertyChange(() => AuthAdfs);
            }
        }

        public event EventHandler<DataErrorsChangedEventArgs> ErrorsChanged;

        bool INotifyDataErrorInfo.HasErrors => _validationErrors.Count > 0;

        IEnumerable INotifyDataErrorInfo.GetErrors(string propertyName)
        {
            if (string.IsNullOrEmpty(propertyName)
                || !_validationErrors.ContainsKey(propertyName))
            {
                return null;
            }

            return _validationErrors[propertyName];
        }

        protected override void OnInitialize()
        {
            base.OnInitialize();

            if (!string.IsNullOrWhiteSpace(Context.AuthenticationSettings.AuthenticationMode))

            {
                //Initialize Only in case of new instance creation
                InitialiseAuthenticationMode(Context.AuthenticationSettings.AuthenticationMode);
            }
            if (!string.IsNullOrWhiteSpace(Context.AuthenticationSettings.TwoFactorAuthenticationMode))
            {
                Initialise2FAMode(Context.AuthenticationSettings.TwoFactorAuthenticationMode);
            }
        }

        private void Initialise2FAMode(string twoFactorAuthenticationMode)
        {
            var tokens = twoFactorAuthenticationMode.Split(',');

            _internal2FA = tokens.Contains(Constants.Authentication2FAModeKeys.Internal);
            _external2FA = tokens.Contains(Constants.Authentication2FAModeKeys.External);
        }

        void InitialiseAuthenticationMode(string authenticationMode)
        {
            var tokens = authenticationMode.Split(',');

            _authForms = tokens.Contains(Constants.AuthenticationModeKeys.Forms);
            _authWindows = tokens.Contains(Constants.AuthenticationModeKeys.Windows);
            _authCpaSso = tokens.Contains(Constants.AuthenticationModeKeys.Sso);
            _authAdfs = tokens.Contains(Constants.AuthenticationModeKeys.Adfs);
        }

        void RaiseErrorsChanged(string propertyName)
        {
            ErrorsChanged?.Invoke(this, new DataErrorsChangedEventArgs(propertyName));
        }

        void Validate()
        {
            if (string.IsNullOrEmpty(AuthenticationMode))
            {
                SetErrors(nameof(AuthenticationMode), new[] { "At least one method is required" });
            }
        }

        void SetErrors(string propertyName, ICollection<string> errors)
        {
            if (errors == null || errors.Count == 0)
            {
                if (_validationErrors.ContainsKey(propertyName))
                {
                    _validationErrors.Remove(propertyName);
                    RaiseErrorsChanged(propertyName);
                }
            }
            else
            {
                _validationErrors[propertyName] = errors;
                RaiseErrorsChanged(propertyName);
            }
        }

        public override void CanClose(Action<bool> callback)
        {
            Validate();
            if (((INotifyDataErrorInfo)this).HasErrors)
            {
                callback(false);
                return;
            }

            callback(true);
        }

        protected override void OnDeactivate(bool close)
        {
            base.OnDeactivate(close);
            Context.SetAuthMode(AuthenticationMode);
            Context.Set2FAMode(Authentication2FAMode);
        }
    }
}