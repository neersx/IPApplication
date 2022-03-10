using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using System.Security.Permissions;

namespace Inprotech.Integration.SchemaMapping.Xsd
{
    [Serializable]
    public class MissingSchemaDependencyException : Exception
    {
        public MissingSchemaDependencyException(IEnumerable<string> missingDependencies)
        {
            MissingDependencies = missingDependencies;
        }

        [SecurityPermission(SecurityAction.Demand, SerializationFormatter = true)]
        protected MissingSchemaDependencyException(SerializationInfo info, StreamingContext context)
            : base(info, context)
        {
            MissingDependencies = (IEnumerable<string>) info.GetValue("MissingDependencies", typeof(IEnumerable<string>));
        }

        public IEnumerable<string> MissingDependencies { get; }

        public override string Message => "Missing dependencies: " + string.Join(",", MissingDependencies);

        [SecurityPermission(SecurityAction.Demand, SerializationFormatter = true)]
        public override void GetObjectData(SerializationInfo info, StreamingContext context)
        {
            info.AddValue("MissingDependencies", MissingDependencies, typeof(IEnumerable<string>));
            base.GetObjectData(info, context);
        }
    }
}