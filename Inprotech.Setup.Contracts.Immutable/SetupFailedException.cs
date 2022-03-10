using System;

namespace Inprotech.Setup.Contracts.Immutable
{
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2237:MarkISerializableTypesWithSerializable")]
    public class SetupFailedException : Exception
    {
        public SetupFailedException(string message) : base(message)
        {            
        }
    }
}