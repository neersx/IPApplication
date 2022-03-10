using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public interface ISecurityContext : ICurrentIdentity
    {
        User User { get; }
    }
}