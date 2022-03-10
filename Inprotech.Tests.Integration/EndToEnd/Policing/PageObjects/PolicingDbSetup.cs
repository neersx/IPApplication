using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects
{
    public class PolicingDbSetup : DbSetup
    {
        readonly CaseBuilder _caseBuilder;

        readonly string _eventName = @"e2e-event-" + typeof (PolicingDbSetup).Name;

        public PolicingDbSetup()
        {
            Users = new Users(DbContext);

            OtherUsers = new OtherUserBuilder(DbContext);

            _caseBuilder = new CaseBuilder(DbContext);
        }
        
        internal PolicingDbSetup WithPolicingServerOff()
        {
            Helpers.SetPolicingServerOff(DbContext);
            return this;
        }

        public Case GetCase(string irn = null)
        {
            var prefixedIrn = Fixture.Prefix(irn);
            return DbContext.Set<Case>().SingleOrDefault(_ => _.Irn == prefixedIrn + "irn") ?? _caseBuilder.Create(prefixedIrn);
        }

        public Data WithWorkflowData()
        {
            var criteria = InsertWithNewId(new Criteria
                                           {
                                               PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                           });

            var @event = InsertWithNewId(new Event
                                         {
                                             Description = _eventName
                                         });

            Insert(new ValidEvent(criteria, @event, _eventName));

            return new Data
                   {
                       Criteria = criteria,
                       Event = @event
                   };
        }
        
        public OtherUserBuilder OtherUsers { get; }

        public Users Users { get; }
        
        public class Data
        {
            public Criteria Criteria { get; set; }

            public Event Event { get; set; }
        }
    }
}