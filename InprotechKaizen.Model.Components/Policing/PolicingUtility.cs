using System;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Policing
{
    public interface IPolicingUtility
    {
        bool IsPoliceImmediately();
    }

    public class PolicingUtility : IPolicingUtility
    {
        readonly IDbContext _dbContext;

        public PolicingUtility(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public bool IsPoliceImmediately()
        {
            return
                _dbContext.Set<SiteControl>()
                    .Any(
                        sc => new[] {SiteControls.PoliceImmediately, SiteControls.PoliceImmediateInBackground}
                            .Contains(sc.ControlId) && sc.BooleanValue == true);
        }
    }
}