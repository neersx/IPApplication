using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class OpenActionBuilder : IBuilder<OpenAction>
    {
        readonly InMemoryDbContext _db;

        public OpenActionBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public Action Action { get; set; }
        public Case Case { get; set; }
        public short? Cycle { get; set; }
        public string Status { get; set; }
        public Criteria Criteria { get; set; }
        public bool? IsOpen { get; set; }

        public OpenAction Build()
        {
            return new OpenAction(
                                  Action ?? new ActionBuilder().Build().In(_db),
                                  Case ?? new CaseBuilder().Build(),
                                  Cycle ?? Fixture.Short(),
                                  Status ?? Fixture.String("Status"),
                                  Criteria ?? new CriteriaBuilder {Action = Action}.Build(),
                                  IsOpen);
        }

        public static OpenActionBuilder ForCaseAsValid(InMemoryDbContext db, Case @case, Action forAction = null, Criteria criteria = null)
        {
            forAction = forAction ?? new ActionBuilder().Build().In(db);
            ValidActionBuilder.ForCase(@case, forAction).Build().In(db);
            criteria = criteria ?? new CriteriaBuilder {Action = forAction}.Build().In(db);

            return new OpenActionBuilder(db)
            {
                Case = @case,
                Action = forAction,
                Criteria = criteria,
                IsOpen = true
            };
        }
    }
}