using System;
using System.Collections.Generic;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Core.Actions
{
    // this class should only be used for testing purpose
    class Error : ISetupAction
    {
        public string Description => "Debug ";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            throw new Exception("Force to stop");
        }
    }
}