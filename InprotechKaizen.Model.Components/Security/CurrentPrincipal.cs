using System.Security.Principal;
using System.Threading;

namespace InprotechKaizen.Model.Components.Security
{
    public interface ICurrentPrincipal
    {
        IIdentity Identity { get; }
    }

    public class CurrentPrincipal : ICurrentPrincipal
    {
        public IIdentity Identity
        {
            get { return Thread.CurrentPrincipal.Identity; }
        }
    }
}
