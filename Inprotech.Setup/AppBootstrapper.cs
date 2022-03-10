using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Threading;
using System.Windows;
using System.Windows.Threading;
using Autofac;
using Caliburn.Micro;
using Inprotech.Setup.Core;
using NLog;
using LogManager = NLog.LogManager;
using MessageBox = Inprotech.Setup.UI.MessageBox;

namespace Inprotech.Setup
{
    public class AppBootstrapper : BootstrapperBase
    {
        static readonly Logger Logger = LogManager.GetCurrentClassLogger();

        IContainer _container;
        bool _instanceLockAcquired;
        Mutex _singleInstanceLock;

        public AppBootstrapper()
        {
            Initialize();
        }

        protected override void Configure()
        {
            var builder = new ContainerBuilder();
            builder.RegisterAssemblyModules(Assembly.GetExecutingAssembly());
            builder.RegisterAssemblyModules(typeof(ISetupSettingsManager).Assembly);
            _container = builder.Build();
            SetupEnvironment.IsUiMode = true;
            SetupEnvironment.Dispatcher = Dispatcher.CurrentDispatcher;
        }

        protected override object GetInstance(Type service, string key)
        {
            return _container.Resolve(service);
        }

        protected override IEnumerable<object> GetAllInstances(Type service)
        {
            var instance = _container.Resolve(service);
            return instance as IEnumerable<object> ?? new[] { instance };
        }

        protected override void BuildUp(object instance)
        {
        }

        protected override void OnStartup(object sender, StartupEventArgs e)
        {
            try
            {
                bool isNew;
                _singleInstanceLock = new Mutex(false, "Global\\{51C452DC-5BBE-40CD-BEF1-A9911D1C5911}", out isNew);
                _instanceLockAcquired = _singleInstanceLock.WaitOne(0);

            }
            catch (AbandonedMutexException)
            {
            }

            if (!_instanceLockAcquired)
            {
                new MessageBox().Alert("Another instance of Inprotech Web Applications Setup Utility is running. You should terminate that instance before starting a new one.", "ERROR! Multiple Instances Running");
                Application.Shutdown();
            }

            try
            {
                if (Directory.Exists(Constants.WorkingDirectory))
                    Directory.Delete(Constants.WorkingDirectory, true);
            }
            catch
            {

            }

            DisplayRootViewFor<IShell>();
        }

        protected override void OnExit(object sender, EventArgs e)
        {
            if (_instanceLockAcquired)
                _singleInstanceLock.ReleaseMutex();
        }

        protected override void OnUnhandledException(object sender, DispatcherUnhandledExceptionEventArgs e)
        {
            Logger.Error(e.Exception);

            var error =
                string.Format(
                    "An error has occurred.\nReview the log file in '{0}' for details.\nResolve the issue prior to running the application again.",
                    Path.Combine(Directory.GetCurrentDirectory(), "logs"));

            System.Windows.MessageBox.Show(error, "Error", MessageBoxButton.OK, MessageBoxImage.Error);

            e.Handled = true;
            Application.Current.Shutdown();
        }
    }
}