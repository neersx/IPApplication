using System;
using System.Collections.Generic;
using System.Reflection;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists.ResponseShaping
{
    public class MaintainabilityActionsFacts
    {
        public class EnrichMethod
        {
            public EnrichMethod()
            {
                _api = new PayloadFixtureApiFixture();
                _fixture = new MaintainabilityActionsFixture();
                _enriched = new Dictionary<string, object>();
            }

            readonly MaintainabilityActionsFixture _fixture;
            readonly PayloadFixtureApiFixture _api;
            readonly Dictionary<string, dynamic> _enriched;
            readonly IEnumerable<Payload> _emptyPayload = new Payload[0];

            [Fact]
            public void ShouldReturnAddEditDeleteMaintainanceActions()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithAddEditDeleteMaintainabilityOption)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);

                Assert.True(_enriched.ContainsKey("MaintainabilityActions"));
                Assert.True(_enriched["MaintainabilityActions"].AllowAdd);
                Assert.True(_enriched["MaintainabilityActions"].AllowEdit);
                Assert.False(_enriched["MaintainabilityActions"].AllowDuplicate);
                Assert.True(_enriched["MaintainabilityActions"].AllowDelete);
            }

            [Fact]
            public void ShouldReturnAddOnlyMaintainanceAction()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithAddOnlyMaintainabilityOption)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);

                Assert.True(_enriched.ContainsKey("MaintainabilityActions"));
                Assert.True(_enriched["MaintainabilityActions"].AllowAdd);
                Assert.False(_enriched["MaintainabilityActions"].AllowEdit);
                Assert.False(_enriched["MaintainabilityActions"].AllowDuplicate);
                Assert.False(_enriched["MaintainabilityActions"].AllowDelete);
            }

            [Fact]
            public void ShouldReturnAllMaintainanceActions()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithAllMaintainabilityOptions)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);

                Assert.True(_enriched.ContainsKey("MaintainabilityActions"));
                Assert.True(_enriched["MaintainabilityActions"].AllowAdd);
                Assert.True(_enriched["MaintainabilityActions"].AllowEdit);
                Assert.True(_enriched["MaintainabilityActions"].AllowDuplicate);
                Assert.True(_enriched["MaintainabilityActions"].AllowDelete);
            }

            [Fact]
            public void ShouldReturnDeleteOnlyMaintainanceAction()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithDeleteOnlyMaintainabilityOption)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);

                Assert.True(_enriched.ContainsKey("MaintainabilityActions"));
                Assert.False(_enriched["MaintainabilityActions"].AllowAdd);
                Assert.False(_enriched["MaintainabilityActions"].AllowEdit);
                Assert.False(_enriched["MaintainabilityActions"].AllowDuplicate);
                Assert.True(_enriched["MaintainabilityActions"].AllowDelete);
            }

            [Fact]
            public void ShouldReturnDuplicateOnlyMaintainanceAction()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithDuplicateOnlyMaintainabilityOption)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);

                Assert.True(_enriched.ContainsKey("MaintainabilityActions"));
                Assert.False(_enriched["MaintainabilityActions"].AllowAdd);
                Assert.False(_enriched["MaintainabilityActions"].AllowEdit);
                Assert.True(_enriched["MaintainabilityActions"].AllowDuplicate);
                Assert.False(_enriched["MaintainabilityActions"].AllowDelete);
            }

            [Fact]
            public void ShouldReturnEditOnlyMaintainanceAction()
            {
                var s = _fixture
                        .WithActionContextFor(_emptyPayload, _api.WithEditOnlyMaintainabilityOption)
                        .Subject;

                s.Enrich(_fixture.ActionContext, _enriched);

                Assert.True(_enriched.ContainsKey("MaintainabilityActions"));
                Assert.False(_enriched["MaintainabilityActions"].AllowAdd);
                Assert.True(_enriched["MaintainabilityActions"].AllowEdit);
                Assert.False(_enriched["MaintainabilityActions"].AllowDuplicate);
                Assert.False(_enriched["MaintainabilityActions"].AllowDelete);
            }
        }

        public class MaintainabilityActionsFixture : IFixture<MaintainabilityActions>
        {
            public MaintainabilityActionsFixture()
            {
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                Subject = new MaintainabilityActions(TaskSecurityProvider);
            }

            public HttpActionExecutedContext ActionContext { get; private set; }

            public ITaskSecurityProvider TaskSecurityProvider { get; }
            public MaintainabilityActions Subject { get; }

            public MaintainabilityActionsFixture WithActionContextFor(object payload, Action action)
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
            [PicklistMaintainabilityActions(allowDelete: false, allowDuplicate: false, allowEdit: false)]
            public void WithAddOnlyMaintainabilityOption()
            {
            }

            [PicklistMaintainabilityActions(allowDelete: false, allowDuplicate: false, allowAdd: false)]
            public void WithEditOnlyMaintainabilityOption()
            {
            }

            [PicklistMaintainabilityActions(allowDuplicate: false, allowEdit: false, allowAdd: false)]
            public void WithDeleteOnlyMaintainabilityOption()
            {
            }

            [PicklistMaintainabilityActions(allowDelete: false, allowEdit: false, allowAdd: false)]
            public void WithDuplicateOnlyMaintainabilityOption()
            {
            }

            [PicklistMaintainabilityActions(allowDuplicate: false)]
            public void WithAddEditDeleteMaintainabilityOption()
            {
            }

            public void WithAllMaintainabilityOptions()
            {
            }
        }
    }
}