using System;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.Events
{
    public interface IValidEventResolver
    {
        /// <summary>
        ///     -- The preferred EventDescription is determined by using the Controlling Action
        ///     -- associated with the Event.  This will be used if the OPENACTION row exists
        ///     -- that matches the Controlling Action otherwise use the description determined
        ///     -- from any OpenAction that references the Event.
        /// </summary>
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        ValidEvent Resolve(Case @case, int eventId);

        /// <summary>
        ///     -- The preferred EventDescription is determined by using the Controlling Action
        ///     -- associated with the Event.  This will be used if the OPENACTION row exists
        ///     -- that matches the Controlling Action otherwise use the description determined
        ///     -- from any OpenAction that references the Event.
        /// </summary>
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "event")]
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        ValidEvent Resolve(Case @case, Event @event);

        /// <summary>
        ///     -- The preferred EventDescription is determined by using the Controlling Action
        ///     -- associated with the Event.  This will be used if the OPENACTION row exists
        ///     -- that matches the Controlling Action otherwise use the description determined
        ///     -- from any OpenAction that references the Event.
        /// </summary>
        ValidEvent Resolve(int caseId, int eventId);
    }

    public class ValidEventResolver : IValidEventResolver
    {
        readonly IDbContext _dbContext;

        public ValidEventResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public ValidEvent Resolve(Case @case, int eventId)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));

            var @event = _dbContext.Set<Event>().SingleOrDefault(_ => _.Id == eventId);

            return Resolve(@case, @event);
        }

        public ValidEvent Resolve(int caseId, int eventId)
        {
            var @case = _dbContext.Set<Case>().SingleOrDefault(_ => _.Id == caseId);
            var @event = _dbContext.Set<Event>().SingleOrDefault(_ => _.Id == eventId);

            return Resolve(@case, @event);
        }

        public ValidEvent Resolve(Case @case, Event @event)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (@event == null) throw new ArgumentNullException(nameof(@event));

            /*
                Select EC.*
                FROM OPENACTION OA   
                JOIN EVENTCONTROL EC ON (EC.CRITERIANO = OA.CRITERIANO)
                JOIN EVENTS E        ON ( E.EVENTNO    = EC.EVENTNO )
                JOIN ACTIONS A       ON ( A.ACTION     = OA.ACTION  )
                WHERE OA.CASEID=@pnCaseId
                and EC.EVENTNO=@pnEventNo
                -- The preferred EventDescription is determined by using the Controlling Action
                -- associated with the Event.  This will be used if the OPENACTION row exists
                -- that matches the Controlling Action otherwise use the description determined
                -- from any OpenAction that references the Event.
                AND ( OA.ACTION = E.CONTROLLINGACTION
                OR   E.CONTROLLINGACTION IS NULL )
            */

            var referencedCriterion = (string.IsNullOrWhiteSpace(@event.ControllingAction)
                    ? @case.OpenActions
                    : @case.OpenActions.Where(_ => _.ActionId == @event.ControllingAction))
                .OrderByDescending(_ => _.PoliceEvents)
                .Select(_ => _.Criteria?.Id)
                .Where(_ => _.HasValue);

            return _dbContext
                .Set<ValidEvent>()
                .FirstOrDefault(_ => _.EventId == @event.Id &&
                                     referencedCriterion.Contains(_.CriteriaId));
        }
    }
}