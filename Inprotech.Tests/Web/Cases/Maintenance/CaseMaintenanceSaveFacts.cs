using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Cases.Maintenance;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.DataValidation;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Maintenance
{
    public class CaseMaintenanceSaveFacts : FactBase
    {
        [Fact]
        public void IfNoTransactionReasonUsesNullAsReasonForChange()
        {
            var fixture = new CaseMaintenanceSaveFixture(Db);
            fixture.SiteConfiguration.TransactionReason.Returns(false);
            fixture.SiteConfiguration.ReasonInternalChange.Returns(Fixture.Integer());

            fixture.Subject.Save(fixture.DefaultCase, null, 1, new CaseMaintenanceSaveModel() { Topics = new Dictionary<string, JObject>() });

            fixture.TransactionRecordal.Received(1)
                   .RecordTransactionFor(Arg.Any<Case>(),
                                         CaseTransactionMessageIdentifier.AmendedCase,
                                         null, Arg.Any<int?>());
        }

        [Fact]
        public void IfTransactionReasonUsesReasonInternalChangeAsReasonForChange()
        {
            var fixture = new CaseMaintenanceSaveFixture(Db);
            var reasonNo = Fixture.Integer();
            fixture.SiteConfiguration.TransactionReason.Returns(true);
            fixture.SiteConfiguration.ReasonInternalChange.Returns(reasonNo);

            fixture.Subject.Save(fixture.DefaultCase, null, 1, new CaseMaintenanceSaveModel() { Topics = new Dictionary<string, JObject>() });

            fixture.TransactionRecordal.Received(1)
                   .RecordTransactionFor(Arg.Any<Case>(),
                                         CaseTransactionMessageIdentifier.AmendedCase,
                                         reasonNo, Arg.Any<int?>());
        }

        [Fact]
        public void CallsSaveToDbContextAndResolvesCorrectComponent()
        {
            var fixture = new CaseMaintenanceSaveFixture(Db);

            fixture.Subject.Save(fixture.DefaultCase, null, 1, new CaseMaintenanceSaveModel() { Topics = new Dictionary<string, JObject>() });

            fixture.ComponentResolver.Received(1).Resolve(KnownComponents.Case);
            Db.Received(1).SaveChanges();
        }

        [Fact]
        public void PolicingEngineCalledWithActionIdCriteriaNo()
        {
            var fixture = new CaseMaintenanceSaveFixture(Db);
            var model = new CaseMaintenanceSaveModel
            {
                Topics = new Dictionary<string, JObject>()
            };
            var @case = fixture.DefaultCase;
            model.Topics.Add("actions", JObject.FromObject(new EventTopicSaveModel
            {
                Rows = new []
                {
                    new EventSaveModel
                    {
                        ActionId = "action1",
                        CriteriaId = 10001,
                        EventNo = @case.CaseEvents.First().EventNo,
                        Cycle = @case.CaseEvents.First().Cycle
                    }
                }
            }));
            fixture.ChangeTracker.HasChanged(Arg.Any<CaseEvent>())
                   .Returns(true);

            fixture.Subject.Save(@case, null, 1, model);

            fixture.ComponentResolver.Received(1).Resolve(KnownComponents.Case);
            Db.Received(1).SaveChanges();
            fixture.PolicingEngine.Received(1).PoliceEvent(@case.CaseEvents.First(), 1002, 1, "actionId");
        }

    }

    public class CaseMaintenanceSaveFixture : IFixture<CaseMaintenanceSave>
    {
        public CaseMaintenanceSaveFixture(IDbContext db)
        {
            ChangeTracker = Substitute.For<IChangeTracker>();
            PolicingEngine = Substitute.For<IPolicingEngine>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            SiteConfiguration = Substitute.For<ISiteConfiguration>();
            TransactionRecordal = Substitute.For<ITransactionRecordal>();
            ComponentResolver = Substitute.For<IComponentResolver>();
            TopicsUpdater = Substitute.For<ITopicsUpdater<Case>>();
            ExternalDataValidator = Substitute.For<IExternalDataValidator>();
            Subject = new CaseMaintenanceSave(db,
                                              ChangeTracker,
                                              PolicingEngine,
                                              SiteConfiguration,
                                              TransactionRecordal,
                                              ComponentResolver,
                                              TopicsUpdater,
                                              ExternalDataValidator);
        }

        public Case DefaultCase
        {
            get
            {
                var @case = new Case(Fixture.Integer(),
                                    Fixture.String(),
                                    new Country(Fixture.String(), Fixture.String()),
                                    new CaseType(Fixture.String(), Fixture.String()),
                                    new PropertyType(Fixture.String(), Fixture.String()),
                                    null);
                @case.CaseEvents.AddAll(new List<CaseEvent>
                {
                    new CaseEvent(@case.Id, Fixture.Short(1000), Fixture.Short(10)){CreatedByCriteriaKey = 1002, CreatedByActionKey = "actionId"}
                });
                return @case;
            }
        }

        public IExternalDataValidator ExternalDataValidator { get; set; }
        public CaseMaintenanceSave Subject { get; }
        public IChangeTracker ChangeTracker { get; set; }
        public ITopicsUpdater<Case> TopicsUpdater { get; set; }
        public IPolicingEngine PolicingEngine { get; set; }
        public ISiteConfiguration SiteConfiguration { get; set; }
        public ITransactionRecordal TransactionRecordal { get; set; }
        public IComponentResolver ComponentResolver { get; set; }
        public ISiteControlReader SiteControlReader { get; set; }
    }
}
