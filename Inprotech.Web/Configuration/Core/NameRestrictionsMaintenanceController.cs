using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Extentions;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Core
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.MaintainNameRestrictions)]
    [RoutePrefix("api/configuration/namerestrictions")]
    public class NameRestrictionsMaintenanceController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        static NameRestrictionActions[] _debtorActions;
        internal NameRestrictionActions[] DebtorActions => _debtorActions ?? (_debtorActions = GetActions());

        static readonly CommonQueryParameters DefaultQueryParameters =
           CommonQueryParameters.Default.Extend(new CommonQueryParameters
           {
               SortBy = "Description",
               SortDir = "asc"
           });

        public NameRestrictionsMaintenanceController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            if (dbContext == null) throw new ArgumentNullException(nameof(dbContext));
            if (preferredCultureResolver == null) throw new ArgumentNullException(nameof(preferredCultureResolver));
            if (lastInternalCodeGenerator == null) throw new ArgumentNullException(nameof(lastInternalCodeGenerator));

            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        public dynamic ViewData()
        {
            return DebtorActions;
        }

        [HttpGet]
        [Route("search")]
        [NoEnrichment]
        public dynamic Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] SearchOptions searchOptions,
                              [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            short? restrictionAction;
            queryParameters = DefaultQueryParameters.Extend(queryParameters);

            var culture = _preferredCultureResolver.Resolve();

            var interimResults = _dbContext.Set<DebtorStatus>().Select(_ => new
                                                                {
                                                                    _.Id,
                                                                    Description = DbFuncs.GetTranslation(_.Status, null, _.StatusTId, culture),
                                                                    _.RestrictionType
                                                                }).AsEnumerable();

            var results = interimResults.Select(_ => new
                                                {
                                                    _.Id,
                                                    _.Description,
                                                    ActionToBeTaken = DebtorActions.Any(da => da.Type == (int) _.RestrictionType) ? DebtorActions.First(da => da.Type == (int) _.RestrictionType).Description : string.Empty,
                                                    RestrictionAction = restrictionAction = (short?) DebtorActions.FirstOrDefault(da => da.Type == (int) _.RestrictionType).Type,
                                                    Severity = NameRestrictionActions.Map.TryGetValue(restrictionAction ?? KnownDebtorRestrictions.NoRestriction, out var value) ? value : string.Empty
                                                });

            if (!string.IsNullOrEmpty(searchOptions?.Text))
                results = results.Where(x => x.Description.IndexOf(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase) > -1);
            
            return results.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);

        }
        
        [HttpGet]
        [Route("{id}")]
        [NoEnrichment]
        public dynamic GetNameRestriction(int id)
        {
            var nameRestriction = _dbContext.Set<DebtorStatus>().Select(_ => new NameRestrictionsSaveDetails
                                                                 {
                                                                     Id = _.Id,
                                                                     Description = _.Status,
                                                                     Password = _.ClearTextPassword,
                                                                     Action = (short)_.RestrictionType
                                                                    
                                                                 }).SingleOrDefault(_ => _.Id == id);

            if (nameRestriction == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);
            return nameRestriction;
        }

        [HttpPost]
        [Route("")]
        public dynamic Save(NameRestrictionsSaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));

            var validationErrors = Validate(saveDetails, Operation.Add).ToArray();
            if (!validationErrors.Any())
            {

                var id = (short)_lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.DebtorStatus);
                var nameRestriction = new DebtorStatus(id)
                {
                    RestrictionType = saveDetails.Action,
                    ClearTextPassword = saveDetails.Password,
                    Status = saveDetails.Description
                    
                };

                _dbContext.Set<DebtorStatus>().Add(nameRestriction);
                _dbContext.SaveChanges();

                return new
                {
                    Result = "success",
                    UpdatedId = id
                };
            }

            return validationErrors.AsErrorResponse();
        }

        [HttpPut]
        [Route("{id}")]
        public dynamic Update(short id, NameRestrictionsSaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));

            var validationErrors = Validate(saveDetails, Operation.Update).ToArray();
            if (!validationErrors.Any())
            {
                var entityToUpdate = _dbContext.Set<DebtorStatus>().FirstOrDefault(_ => _.Id == id);

                if(entityToUpdate == null)
                    throw new HttpResponseException(HttpStatusCode.NotFound);

                entityToUpdate.RestrictionType = saveDetails.Action;
                entityToUpdate.ClearTextPassword = saveDetails.Password;
                entityToUpdate.Status = saveDetails.Description;

                _dbContext.SaveChanges();

                return new
                {
                    Result = "success",
                    UpdatedId = entityToUpdate.Id
                };
            }

            return validationErrors.AsErrorResponse();
        }
        
        [HttpPost]
        [Route("delete")]
        [NoEnrichment]
        public DeleteResponseModel Delete(DeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var nameRestrictions = _dbContext.Set<DebtorStatus>().
                                            Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();

                response.InUseIds = new List<int>();

                foreach (var nameRestriction in nameRestrictions)
                {
                    try
                    {
                        _dbContext.Set<DebtorStatus>().Remove(nameRestriction);
                        _dbContext.SaveChanges();
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(nameRestriction.Id);
                        }
                        _dbContext.Detach(nameRestriction);
                    }
                }

                txScope.Complete();

                if (response.InUseIds.Any())
                {
                    response.HasError = true;
                    response.Message = ConfigurationResources.InUseErrorMessage;
                    return response;
                }
            }
            return response;
        }

        IEnumerable<Infrastructure.Validations.ValidationError> Validate(NameRestrictionsSaveDetails nameRestriction, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(nameRestriction))
                yield return validationError;
            var all = _dbContext.Set<DebtorStatus>().ToArray();

            var others = operation == Operation.Update ? all.Where(_ => _.Id != nameRestriction.Id).ToArray() : all;
            if (others.Any(_ => _.Status.IgnoreCaseEquals(nameRestriction.Description)))
            {
                yield return ValidationErrors.NotUnique(string.Format(Resources.ErrorDuplicateNameRestrictionDescription, nameRestriction.Description), "description");
            }

            if (nameRestriction.Action == KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation && string.IsNullOrWhiteSpace(nameRestriction.Password))
            {
                yield return ValidationErrors.Required("password");
            }
        }
        
        static NameRestrictionActions[] GetActions()
        {
            var actions = new[]
            {
                new NameRestrictionActions(KnownDebtorRestrictions.DisplayError, ConfigurationResources.DisplayError),
                new NameRestrictionActions(KnownDebtorRestrictions.DisplayWarning, ConfigurationResources.DisplayWarning),
                new NameRestrictionActions(KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, ConfigurationResources.DisplayWarningPromptPassword),
                new NameRestrictionActions(KnownDebtorRestrictions.NoRestriction, ConfigurationResources.NoAction)
            };
            return actions;
        }
    }
    
    public class NameRestrictionsSaveDetails
    {
        [Required]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Description { get; set; }

        [Required]
        public short Action { get; set; }

        [MaxLength(10)]
        public string Password { get; set; }
    }

    public class NameRestrictionActions
    {
        public NameRestrictionActions(int type, string description)
        {
            Type = type;
            Description = description;
        }

        public static readonly Dictionary<short?, string> Map = new Dictionary<short?, string>
        {
            {KnownDebtorRestrictions.DisplayError, "error"},
            {KnownDebtorRestrictions.DisplayWarning, "warning"},
            {KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, "warning"},
            {KnownDebtorRestrictions.NoRestriction, "information"},
            {short.MinValue, null}
        };

        public int Type { get; set; }
        public string Description { get; set; }
    }
}
