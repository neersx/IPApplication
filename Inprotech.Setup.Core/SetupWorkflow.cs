using System;
using System.Collections.Generic;
using System.Linq;
using Autofac;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Actions;

namespace Inprotech.Setup.Core
{
    public class SetupWorkflow
    {
        readonly List<ISetupAction> _actions = new List<ISetupAction>();
        readonly IComponentContext _container;

        public SetupWorkflow(IComponentContext container)
        {
            _container = container;
        }

        public Action<SetupContext> InitContext { get; private set; }

        public ISetupAction Next()
        {
            if (_actions.Any())
            {
                var a = _actions[0];
                _actions.RemoveAt(0);

                return a;
            }

            return null;
        }

        public ISetupAction Peek()
        {
            if (_actions.Any())
            {
                return _actions[0];
            }

            return null;
        }

        internal SetupWorkflow Prepend(IEnumerable<ISetupAction> actions)
        {
            foreach (var action in actions.Reverse())
                _actions.Insert(0, action);

            return this;
        }

        internal SetupWorkflow Clear()
        {
            _actions.Clear();

            return this;
        }

        public SetupWorkflow Status(SetupStatus status)
        {
            return Do<UpdateStatus>(_ => _.Status = status);
        }

        public SetupWorkflow Load(Func<ISetupActionBuilder, IEnumerable<IEnumerable<ISetupAction>>> setupActions)
        {
            return Do<LoadSetupActions>(_ => _.Build = setupActions);
        }

        public SetupWorkflow TryLoad(Func<ISetupActionBuilder, IEnumerable<IEnumerable<ISetupAction>>> setupActions)
        {
            return Do<LoadSetupActions>(_ => { _.Build = setupActions; _.IgnoreNotFound = true; });
        }

        public SetupWorkflow Do<T>() where T : ISetupAction
        {
            var action = _container.Resolve<Func<T>>()();
            return Append(action);
        }

        public SetupWorkflow Do<T>(Action<T> setup) where T : ISetupAction
        {
            var action = _container.Resolve<Func<T>>()();
            setup(action);
            return Append(action);
        }

        public SetupWorkflow Context(Action<SetupContext> initContext)
        {
            InitContext = initContext;
            return this;
        }

        internal SetupWorkflow Append(ISetupAction action)
        {
            _actions.Add(action);
            return this;
        }
    }
}