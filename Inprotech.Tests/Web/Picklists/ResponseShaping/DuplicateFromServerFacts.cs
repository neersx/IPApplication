using System;
using System.Collections.Generic;
using System.Reflection;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Xunit;

namespace Inprotech.Tests.Web.Picklists.ResponseShaping
{
    public class DuplicateFromServerFacts
    {
        public class EnrichMethod
        {
            public EnrichMethod()
            {
                _api = new PayloadFixtureApiFixture();
                _fixture = new DuplicateFromServerFixture();
                _enriched = new Dictionary<string, object>();
            }

            readonly DuplicateFromServerFixture _fixture;
            readonly PayloadFixtureApiFixture _api;
            readonly Dictionary<string, dynamic> _enriched;
            readonly IEnumerable<Payload> _emptyPayload = new Payload[0];

            [Fact]
            public void ShouldEnrichWithApplicationTask()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithDeclaredApplicationTask)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);
                Assert.True(_enriched.ContainsKey("DuplicateFromServer"));
            }

            [Fact]
            public void ShouldEnrichWithMultipleApplicationTasks()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithMultipleApplicationTasks)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);
                Assert.True(_enriched.ContainsKey("DuplicateFromServer"));
            }

            [Fact]
            public void ShouldNotEnrichIfNotSpecified()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithMultipleTasksWithoutFlag)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);
                Assert.False(_enriched.ContainsKey("DuplicateFromServer"));

                s = _fixture
                    .WithActionContextFor(_emptyPayload, _api.WithDeclaredTaskWithoutFlag)
                    .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);
                Assert.False(_enriched.ContainsKey("DuplicateFromServer"));
            }

            [Fact]
            public void ShouldNotEnrichWithoutApplicationTasks()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithoutApplicationTask)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);
                Assert.False(_enriched.ContainsKey("DuplicateFromServer"));
            }
        }

        public class PayloadFixtureApiFixture
        {
            [PicklistPayload(typeof(Payload), ApplicationTask.MaintainWorkflowRules, ApplicationTask.MaintainWorkflowRulesProtected, true)]
            public void WithMultipleApplicationTasks()
            {
            }

            [PicklistPayload(typeof(Payload), ApplicationTask.MaintainWorkflowRules, ApplicationTask.MaintainWorkflowRulesProtected)]
            public void WithMultipleTasksWithoutFlag()
            {
            }

            [PicklistPayload(typeof(Payload), ApplicationTask.MaintainBaseInstructions, true)]
            public void WithDeclaredApplicationTask()
            {
            }

            [PicklistPayload(typeof(Payload), ApplicationTask.MaintainBaseInstructions)]
            public void WithDeclaredTaskWithoutFlag()
            {
            }

            [PicklistPayload(typeof(Payload), ApplicationTask.NotDefined, true)]
            public void WithDeclaredUndefinedApplicationTask()
            {
            }

            [PicklistPayload(typeof(Payload))]
            public void WithoutApplicationTask()
            {
            }
        }

        public class Payload
        {
        }

        public class DuplicateFromServerFixture : IFixture<DuplicateFromServer>
        {
            public DuplicateFromServerFixture()
            {
                Subject = new DuplicateFromServer();
            }

            public HttpActionExecutedContext ActionContext { get; private set; }
            public DuplicateFromServer Subject { get; }

            public DuplicateFromServerFixture WithActionContextFor(object payload, Action action)
            {
                ActionContext = TestHelper.CreateActionExecutedContext(payload, Of(action));
                return this;
            }

            public MethodInfo Of(Action a)
            {
                return a.Method;
            }
        }
    }
}