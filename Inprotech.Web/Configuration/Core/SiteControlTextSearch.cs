using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Core
{
    public static class SiteControlTextSearch
    {
        public static IQueryable<SiteControl> SearchText(this IQueryable<SiteControl> results, SiteControlSearchOptions searchOptions, string preferredCulture)
        {
            if (searchOptions.IsByName)
            {
                var textSearchResult = results
                                    .Select(_ => new SiteControlSearchModel
                                    {
                                        Id = _.Id,
                                        ControlId = _.ControlId,
                                        IntegerValue = _.IntegerValue,
                                        DecimalValue = _.DecimalValue,
                                        BooleanValue = _.BooleanValue,
                                        StringValue = _.StringValue,
                                        SiteControlDescription = DbFuncs.GetTranslation(_.SiteControlDescription, null, _.SiteControlDescriptionTId, preferredCulture)
                                    })
                                    .ToArray()
                                    .Where(_ => (searchOptions.IsByValue && _.SearchInValue(searchOptions.Text))
                                               || (searchOptions.IsByName && _.ControlId.TextContains(searchOptions.Text))
                                               || (searchOptions.IsByDescription && _.SiteControlDescription.IgnoreCaseContains(searchOptions.Text)))
                                    .Select(_ => _.Id)
                                    .ToArray();

                return results.Where(_ => textSearchResult.Contains(_.Id));
            }

            if (searchOptions.IsByValue || searchOptions.IsByDescription)
            {
                return results
                                .Where(_ => (searchOptions.IsByValue &&
                                            (_.IntegerValue.ToString().Contains(searchOptions.Text) || _.DecimalValue.ToString().Contains(searchOptions.Text)
                                             || _.BooleanValue.ToString() == searchOptions.Text || _.StringValue.Contains(searchOptions.Text)))
                                             || (searchOptions.IsByDescription && DbFuncs.GetTranslation(_.SiteControlDescription, null, _.SiteControlDescriptionTId, preferredCulture).Contains(searchOptions.Text))
                    );
            }
            return results;
        }
    }

    public class SiteControlSearchModel
    {
        static string GetStringValue(object o)
        {
            return o?.ToString() ?? string.Empty;
        }

        static bool ContainsValue(object o, string text)
        {
            return GetStringValue(o).IgnoreCaseContains(text);
        }

        public int Id { get; set; }

        public string ControlId { get; set; }

        public int? IntegerValue { get; set; }

        public decimal? DecimalValue { get; set; }

        public bool? BooleanValue { get; set; }

        public string StringValue { get; set; }

        private string _description;
        public string SiteControlDescription
        {
            get { return _description; }
            set
            {
                _description = value;
                if (string.IsNullOrEmpty(value))
                    _description = string.Empty;
            }
        }

        public bool SearchInValue(string searchText)
        {
            return ContainsValue(IntegerValue, searchText) || ContainsValue(DecimalValue, searchText)
                || ContainsValue(BooleanValue, searchText) || ContainsValue(StringValue, searchText);
        }
    }
}