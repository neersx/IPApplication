using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class ValidActionBuilder : IBuilder<ValidAction>
    {
        public string ActionName { get; set; }
        public Action Action { get; set; }
        public CaseType CaseType { get; set; }
        public Country Country { get; set; }
        public PropertyType PropertyType { get; set; }
        public short? Sequence { get; set; }

        public ValidAction Build()
        {
            var action = Action ?? new ActionBuilder().Build();
            return new ValidAction(
                                   ActionName ?? action.Name,
                                   action,
                                   Country ?? new CountryBuilder().Build(),
                                   CaseType ?? new CaseTypeBuilder().Build(),
                                   PropertyType ?? new PropertyTypeBuilder().Build()) {DisplaySequence = Sequence};
        }

        public static ValidActionBuilder ForCase(Case @case, Action action)
        {
            return new ValidActionBuilder
            {
                Action = action,
                CaseType = @case.Type,
                Country = @case.Country,
                PropertyType = @case.PropertyType
            };
        }

        public static ValidActionBuilder ForCase(Case @case)
        {
            return ForCase(@case, new ActionBuilder().Build());
        }
    }

    public static class ValidActionBuilderExtensions
    {
        public static ValidActionBuilder ForAnyCountry(this ValidActionBuilder source)
        {
            source.Country = new CountryBuilder {Id = KnownValues.DefaultCountryCode}.Build();
            return source;
        }
    }
}