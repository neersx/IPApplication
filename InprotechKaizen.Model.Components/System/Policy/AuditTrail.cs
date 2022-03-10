using System;
using Inprotech.Infrastructure.Policy;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;

namespace InprotechKaizen.Model.Components.System.Policy
{
    public class AuditTrail : IAuditTrail
    {
        readonly IContextInfo _contextInfo;

        public AuditTrail(IContextInfo contextInfo)
        {
            _contextInfo = contextInfo ?? throw new ArgumentNullException(nameof(contextInfo));
        }

        public void Start(int? componentId = null)
        {
            _contextInfo.EnsureUserContext(componentId: componentId);
        }
    }
}