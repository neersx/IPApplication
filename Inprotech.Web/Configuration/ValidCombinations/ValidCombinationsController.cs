using Autofac.Features.Metadata;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Persistence;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    [Authorize]
    [RoutePrefix("api/configuration/validcombination")]
    public class ValidCombinationsController : ApiController
    {
        readonly IEnumerable<Meta<Func<IValidCombinationBulkController>>> _metaBulkController;
        readonly IDbContext _dbContext;

        public ValidCombinationsController(IDbContext dbContext, IEnumerable<Meta<Func<IValidCombinationBulkController>>> metaBulkController)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (metaBulkController == null) throw new ArgumentNullException("metaBulkController");

            _metaBulkController = metaBulkController;
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic ViewData()
        {
            var searchTypes = new []
            {
                new ValidCombinationSearchType("default", "Select Characteristic"),
                new ValidCombinationSearchType(KnownValidCombinationSearchTypes.AllCharacteristics, ConfigurationResources.AllCharacteristics),
                new ValidCombinationSearchType(KnownValidCombinationSearchTypes.Action, ConfigurationResources.ValidAction),
                new ValidCombinationSearchType(KnownValidCombinationSearchTypes.Basis, ConfigurationResources.ValidBasis),
                new ValidCombinationSearchType(KnownValidCombinationSearchTypes.Category, ConfigurationResources.ValidCategory),
                new ValidCombinationSearchType(KnownValidCombinationSearchTypes.Checklist, ConfigurationResources.ValidChecklist),
                new ValidCombinationSearchType(KnownValidCombinationSearchTypes.PropertyType, ConfigurationResources.ValidPropertyType),
                new ValidCombinationSearchType(KnownValidCombinationSearchTypes.Relationship, ConfigurationResources.ValidRelationship),
                new ValidCombinationSearchType(KnownValidCombinationSearchTypes.Status, ConfigurationResources.ValidStatus),
                new ValidCombinationSearchType(KnownValidCombinationSearchTypes.SubType, ConfigurationResources.ValidSubType)
            };

            return searchTypes;
        }

        [HttpPost]
        [Route("copy")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic BulkCopy(BulkCopyDetails bulkCopyDetails)
        {
            if (bulkCopyDetails == null) throw new ArgumentNullException("bulkCopyDetails");
            const string propertyType = "PropertyType";
            const string category = "Category";
            using (var txScope = _dbContext.BeginTransaction())
            {
                if (bulkCopyDetails.PropertyType)
                    CopyByValidCombinationType(bulkCopyDetails, propertyType);

                if (bulkCopyDetails.Category)
                    CopyByValidCombinationType(bulkCopyDetails, category);

                foreach (var searchType in GetSelectedCharacteristics(bulkCopyDetails))
                {
                    if(searchType == propertyType || searchType == category) continue;
                    CopyByValidCombinationType(bulkCopyDetails, searchType);
                }

                txScope.Complete();
            }
            return new {Result = "success"};
        }

        private void CopyByValidCombinationType(BulkCopyDetails bulkCopyDetails, string searchType)
        {
            var bulkController = _metaBulkController
                .Single(
                        _ =>
                            _.Metadata["Name"].ToString()
                             .Equals(searchType, StringComparison.InvariantCultureIgnoreCase))
                .Value();

            bulkController.Copy(bulkCopyDetails.FromJurisdiction, bulkCopyDetails.ToJurisdictions);
        }

        IEnumerable<string> GetSelectedCharacteristics(BulkCopyDetails copyDetails)
        {
            return (from property in copyDetails.GetType().GetProperties().Where(_ => _.PropertyType == typeof(bool))
                let propValue = copyDetails.GetType().GetProperty(property.Name).GetValue(copyDetails)
                where propValue.ToString().Equals("true",StringComparison.InvariantCultureIgnoreCase)
                select property.Name).ToList();
        }
    }

    public class BulkCopyDetails
    {
        public CountryModel[] ToJurisdictions { get; set; }

        public CountryModel FromJurisdiction { get; set; }

        public bool Action { get; set; }

        public bool Basis { get; set; }

        public bool Category { get; set; }

        public bool Checklist { get; set; }

        public bool PropertyType { get; set; }

        public bool Relationship { get; set; }

        public bool SubType { get; set; }

        public bool Status { get; set; }
    }

    public class ValidCombinationSearchType
    {
        public ValidCombinationSearchType(string type, string description)
        {
            Type = type;
            Description = description;
        }

        public string Type { get; set; }
        public string Description { get; set; }
    }
}
