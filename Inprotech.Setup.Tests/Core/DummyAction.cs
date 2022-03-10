using System;
using System.Collections.Generic;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Tests.Core
{
    internal class DummyAction : ISetupAction
    {
        public string Description { get; private set; }
        public bool ContinueOnException { get; private set; }

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
        }
    }

    internal class ErrorAction : ISetupAction
    {
        public string Description { get; private set; }
        public bool ContinueOnException { get; private set; }

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            throw new NotImplementedException();
        }
    }

    internal class ErrorContinueAction : ISetupAction
    {
        public string Description { get; private set; }
        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            throw new NotImplementedException();
        }
    }
}