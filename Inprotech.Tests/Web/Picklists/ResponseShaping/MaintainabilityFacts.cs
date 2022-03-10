using System;
using System.Collections.Generic;
using System.Reflection;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Picklists.ResponseShaping;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists.ResponseShaping
{
    public class MaintainabilityFacts
    {
        public class EnrichMethod
        {
            public EnrichMethod()
            {
                _api = new PayloadFixtureApiFixture();
                _fixture = new MaintainabilityFixture();
                _enriched = new Dictionary<string, object>();
            }

            readonly MaintainabilityFixture _fixture;
            readonly PayloadFixtureApiFixture _api;
            readonly Dictionary<string, dynamic> _enriched;
            readonly IEnumerable<Payload> _emptyPayload = new Payload[0];

            [Theory]
            [InlineData(false, true, true)]
            [InlineData(true, false, true)]
            [InlineData(true, true, false)]
            [InlineData(true, true, true)]
            public void ShouldReturnAccessAsProvidedForFineGrainControlledTask(bool canAdd, bool canUpdate, bool canDelete)
            {
                var s = _fixture
                        .WithTask(canAdd, canUpdate, canDelete)
                        .WithActionContextFor(_emptyPayload, _api.WithDeclaredApplicationTask)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);

                Assert.Equal(canAdd, _enriched["Maintainability"].CanAdd);
                Assert.Equal(canUpdate, _enriched["Maintainability"].CanEdit);
                Assert.Equal(canDelete, _enriched["Maintainability"].CanDelete);
            }

            [Theory]
            [InlineData(false, true, true)]
            [InlineData(true, false, true)]
            [InlineData(true, true, false)]
            [InlineData(true, true, true)]
            public void ShouldReturnExpectedResultsForMultipleSecurityTasks(bool canAdd, bool canUpdate, bool canDelete)
            {
                var s = _fixture
                        .WithTask(ApplicationTask.MaintainWorkflowRules)
                        .WithTask(ApplicationTask.MaintainWorkflowRulesProtected, canAdd, canUpdate, canDelete)
                        .WithActionContextFor(_emptyPayload, _api.WithMultipleApplicationTasks)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);

                Assert.Equal(canAdd, _enriched["Maintainability"].CanAdd);
                Assert.Equal(canUpdate, _enriched["Maintainability"].CanEdit);
                Assert.Equal(canDelete, _enriched["Maintainability"].CanDelete);
            }

            [Fact]
            public void ShouldEnrich()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithDeclaredApplicationTask)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);

                Assert.True(_enriched.ContainsKey("Maintainability"));
            }

            [Fact]
            public void ShouldReturnFullAccessIfAllowedAccessAlways()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithAlwaysAllowedAccess)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);

                Assert.True(_enriched["Maintainability"].CanAdd);
                Assert.True(_enriched["Maintainability"].CanEdit);
                Assert.True(_enriched["Maintainability"].CanDelete);
            }

            [Fact]
            public void ShouldReturnFullAccessIfExecuteAccessIsGranted()
            {
                var s = _fixture
                        .WithTask(canExecute: true)
                        .WithActionContextFor(_emptyPayload, _api.WithDeclaredApplicationTask)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);

                Assert.True(_enriched["Maintainability"].CanAdd);
                Assert.True(_enriched["Maintainability"].CanEdit);
                Assert.True(_enriched["Maintainability"].CanDelete);
            }

            [Fact]
            public void ShouldReturnNoAccessIfNoTaskIsProvided()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithoutApplicationTask)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);

                Assert.False(_enriched["Maintainability"].CanAdd);
                Assert.False(_enriched["Maintainability"].CanEdit);
                Assert.False(_enriched["Maintainability"].CanDelete);
            }

            [Fact]
            public void ShouldReturnNoAccessIfTaskIsNotDefined()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithDeclaredUndefinedApplicationTask)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);

                Assert.False(_enriched["Maintainability"].CanAdd);
                Assert.False(_enriched["Maintainability"].CanEdit);
                Assert.False(_enriched["Maintainability"].CanDelete);
            }
        }

        public class MaintainabilityFixture : IFixture<Maintainability>
        {
            public MaintainabilityFixture()
            {
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                Subject = new Maintainability(TaskSecurityProvider);
            }

            public ITaskSecurityProvider TaskSecurityProvider { get; set; }

            public HttpActionExecutedContext ActionContext { get; private set; }

            public Maintainability Subject { get; }

            public MaintainabilityFixture WithTask(bool canAdd = false, bool canUpdate = false, bool canDelete = false,
                                                   bool canExecute = false)
            {
                TaskSecurityProvider.ListAvailableTasks()
                                    .ReturnsForAnyArgs(new[]
                                    {
                                        new ValidSecurityTask(
                                                              (short)
                                                              ApplicationTask
                                                                  .MaintainBaseInstructions, canAdd,
                                                              canUpdate, canDelete, canExecute)
                                    });
                return this;
            }

            public MaintainabilityFixture WithTask(ApplicationTask task, bool canAdd = false, bool canUpdate = false, bool canDelete = false, bool canExecute = false)
            {
                TaskSecurityProvider.ListAvailableTasks()
                                    .ReturnsForAnyArgs(new[]
                                    {
                                        new ValidSecurityTask(
                                                              (short)
                                                              task, canAdd,
                                                              canUpdate, canDelete, canExecute)
                                    });
                return this;
            }

            public MaintainabilityFixture WithActionContextFor(object payload, Action action)
            {
                ActionContext = TestHelper.CreateActionExecutedContext(payload, Of(action));
                return this;
            }

            public MethodInfo Of(Action a)
            {
                return a.Method;
            }
        }

        public class Payload
        {
        }

        public class PayloadFixtureApiFixture
        {
            [PicklistPayload(typeof(Payload), ApplicationTask.MaintainWorkflowRules, ApplicationTask.MaintainWorkflowRulesProtected)]
            public void WithMultipleApplicationTasks()
            {
            }

            [PicklistPayload(typeof(Payload), ApplicationTask.MaintainBaseInstructions)]
            public void WithDeclaredApplicationTask()
            {
            }

            [PicklistPayload(typeof(Payload), ApplicationTask.AllowedAccessAlways)]
            public void WithAlwaysAllowedAccess()
            {
            }

            [PicklistPayload(typeof(Payload))]
            public void WithDeclaredUndefinedApplicationTask()
            {
            }

            [PicklistPayload(typeof(Payload))]
            public void WithoutApplicationTask()
            {
            }
        }
    }
}