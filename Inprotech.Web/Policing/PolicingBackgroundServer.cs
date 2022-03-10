using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Policing
{
    public enum PolicingServerStatus
    {
        Waiting,
        Running,
        Stopped
    }

    public interface IPolicingBackgroundServer
    {
        PolicingServerStatus Status();

        void TurnOff();

        void TurnOn();
    }

    public class PolicingBackgroundServer : IPolicingBackgroundServer
    {
        readonly IDbContext _dbContext;
        readonly IPolicingServerSps _policingServerSps;
        readonly ISiteControlReader _siteControlReader;

        public PolicingBackgroundServer(IDbContext dbContext, ISiteControlReader siteControlReader, IPolicingServerSps policingServerSps)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
            _policingServerSps = policingServerSps;
        }

        public PolicingServerStatus Status()
        {
            return _policingServerSps.PolicingBackgroundProcessExists()
                ? PolicingServerStatus.Running 
                : PolicingServerStatus.Stopped;
        }

        public void TurnOff()
        {
            var siteControlPoliceContinuously = _dbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.PoliceContinuously);
            siteControlPoliceContinuously.BooleanValue = false;
            _dbContext.SaveChanges();
        }

        public void TurnOn()
        {
            int? identityId = null;
            var siteControlBackgroundProcessLoginId = _siteControlReader.Read<string>(SiteControls.BackgroundProcessLoginId);
            var siteControlPolicingContinuouslyPollingTime = _siteControlReader.Read<int?>(SiteControls.PolicingContinuouslyPollingTime);

            var backgroundUser = _dbContext.Set<User>().FirstOrDefault(_ => _.UserName == siteControlBackgroundProcessLoginId);
            if (backgroundUser != null)
            {
                identityId = backgroundUser.Id;
            }

            _policingServerSps.PolicingStartContinuously(identityId, siteControlPolicingContinuouslyPollingTime);
        }
    }
}