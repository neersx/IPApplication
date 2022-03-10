using Inprotech.Integration;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Fakes;
using System;
using System.Linq;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class ScheduleExecutionManagerFacts : FactBase
    {
        public class FindBySesionMethod : FactBase
        {
            [Fact]
            public void ShouldFindScheduleExecutionBySessionId()
            {
                var guid = Guid.NewGuid();

                var se = new ScheduleExecution
                {
                    SessionGuid = guid
                }.In(Db);

                var manager = new ScheduleExecutionManager(Db, Fixture.Today);

                Assert.Equal(se, manager.FindBySession(guid));
            }
        }

        public class UpdateCasesProcessedMethod : FactBase
        {
            public UpdateCasesProcessedMethod()
            {
                _manager = new ScheduleExecutionManager(Db, Fixture.Today);
            }

            readonly IScheduleExecutionManager _manager;

            [Fact]
            public void ShouldAddForMissingCaseIds()
            {
                var session = new ScheduleExecution(Guid.NewGuid(), new Schedule().In(Db), Fixture.Today()).In(Db);

                session.CasesProcessed = 1;

                var existing = new ScheduleExecutionArtifact
                {
                    ScheduleExecutionId = session.Id,
                    CaseId = Fixture.Integer()
                }.In(Db);

                var caseIds = new[]
                {
                    Fixture.Integer(),
                    existing.CaseId.GetValueOrDefault(),
                    Fixture.Integer()
                };

                _manager.UpdateCasesProcessed(session, caseIds);

                var db = Db.Set<ScheduleExecutionArtifact>();

                Assert.Equal(caseIds.OrderBy(_ => _), db.Select(_ => _.CaseId.Value).OrderBy(_ => _));

                Assert.Equal(3, session.CasesProcessed);
            }

            [Fact]
            public void ShouldUpdateInBulk()
            {
                var session = new ScheduleExecution(Guid.NewGuid(), new Schedule().In(Db), Fixture.Today()).In(Db);

                var caseIds = new[]
                {
                    Fixture.Integer(),
                    Fixture.Integer(),
                    Fixture.Integer()
                };

                _manager.UpdateCasesProcessed(session, caseIds);

                var db = Db.Set<ScheduleExecutionArtifact>();

                Assert.Equal(caseIds, db.Select(_ => _.CaseId.Value));

                Assert.Equal(3, session.CasesProcessed);
            }

            [Fact]
            public void ShouldRemoveRecoverableItems()
            {
                var session = new ScheduleExecution(Guid.NewGuid(), new Schedule() { Type = ScheduleType.Retry }.In(Db), Fixture.Today()).In(Db);

                new ScheduleRecoverable(session, new Case() { Id = 1 }.In(Db), DateTime.Now).In(Db);
                var caseIds = new[]
                {
                    1,
                    Fixture.Integer()
                };

                _manager.UpdateCasesProcessed(session, caseIds);
                Assert.Empty(Db.Set<ScheduleRecoverable>());
            }
        }

        public class AddArtefactOnCaseProcessedMethod : FactBase
        {
            public AddArtefactOnCaseProcessedMethod()
            {
                _manager = new ScheduleExecutionManager(Db, Fixture.Today);
            }

            readonly IScheduleExecutionManager _manager;

            [Fact]
            public void ShouldAddArtifactForCaseIfNotIncluded()
            {
                var se = new ScheduleExecution
                {
                    Id = 1,
                    Schedule = new Schedule(){ Type = ScheduleType.OnDemand }
                }.In(Db);

                var artifacts = new byte[0];

                _manager.AddArtefactOnCaseProcessed(se, 1, artifacts);

                var artifact = Db.Set<ScheduleExecutionArtifact>().Single();

                Assert.Equal(1, artifact.ScheduleExecutionId);
                Assert.Equal(1, artifact.CaseId);
                Assert.Equal(1, se.CasesProcessed);
                Assert.Equal(artifacts, artifact.Blob);
            }

            [Fact]
            public void ShouldNotCountNonCaseArtifactsInCaseInclusion()
            {
                var se = new ScheduleExecution
                {
                    Id = 1,
                    Schedule = new Schedule(){ Type = ScheduleType.OnDemand },
                    CasesProcessed = 2
                }.In(Db);

                new ScheduleExecutionArtifact
                {
                    ScheduleExecutionId = 1,
                    CaseId = 1
                }.In(Db);

                new ScheduleExecutionArtifact
                {
                    ScheduleExecutionId = 1,
                    CaseId = 2
                }.In(Db);

                new ScheduleExecutionArtifact
                {
                    ScheduleExecutionId = 1
                }.In(Db);

                _manager.AddArtefactOnCaseProcessed(se, 1, new byte[0]);

                Assert.Equal(3, Db.Set<ScheduleExecutionArtifact>().Count());
                Assert.Equal(2, se.CasesProcessed);
            }

            [Fact]
            public void ShouldNotUpdateCountIfAlreadyIncluded()
            {
                var se = new ScheduleExecution
                {
                    Id = 1,
                    Schedule = new Schedule(){ Type = ScheduleType.OnDemand },
                    CasesProcessed = 1
                }.In(Db);

                new ScheduleExecutionArtifact
                {
                    ScheduleExecutionId = 1,
                    CaseId = 1
                }.In(Db);

                _manager.AddArtefactOnCaseProcessed(se, 1, new byte[0]);

                Assert.Equal(1, Db.Set<ScheduleExecutionArtifact>().Count());
                Assert.Equal(1, se.CasesProcessed);
            }

            [Fact]
            public void ShouldUpdateCaseArtifactIfAlreadyIncluded()
            {
                var blob = new byte[0];

                var se = new ScheduleExecution
                {
                    Id = 1,
                    Schedule = new Schedule(){ Type = ScheduleType.OnDemand },
                    CasesProcessed = 1
                }.In(Db);

                var a = new ScheduleExecutionArtifact
                {
                    ScheduleExecutionId = 1,
                    CaseId = 1
                }.In(Db);

                _manager.AddArtefactOnCaseProcessed(se, 1, blob);

                Assert.Equal(blob, a.Blob);
            }
        }
    }
}