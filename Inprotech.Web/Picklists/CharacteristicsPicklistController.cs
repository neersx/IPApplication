using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/characteristics")]
    public class CharacteristicsPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public CharacteristicsPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route]
        public PagedResults Characteristics([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                            CommonQueryParameters queryParameters = null, string search = "", string instructionTypeCode = "")
        {
            return Helpers.GetPagedResults(MatchingItems(search, instructionTypeCode),
                                           queryParameters,
                                           null, x => x.Description, search);
        }

        IEnumerable<Characteristic> MatchingItems(string search = "", string instructionTypeCode = "")
        {
            var culture = _preferredCultureResolver.Resolve();
            var instructionTypeProvided = !string.IsNullOrWhiteSpace(instructionTypeCode);
            var interim = _dbContext.Set<InprotechKaizen.Model.StandingInstructions.Characteristic>()
                                    .Where(_ => !instructionTypeProvided || _.InstructionTypeCode == instructionTypeCode)
                                    .Select(_ => new Characteristic
                                    {
                                        Id = _.Id,
                                        Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
                                    }).OrderBy(_ => _.Description);

            var r = interim.ToArray();

            return !string.IsNullOrWhiteSpace(search)
                ? r.Where(_ => _.Description.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1)
                : r;
        }
    }

    public class Characteristic
    {

        [PicklistKey]
        public short Id { get; set; }

        [Required]
        [MaxLength(50)]
        [PicklistDescription]
        public string Description { get; set; }
    }
}
