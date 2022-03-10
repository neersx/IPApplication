using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Extentions;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using Name = Inprotech.Web.Picklists.Name;
using ValidationError = Inprotech.Infrastructure.Validations.ValidationError;

namespace Inprotech.Web.Configuration.Offices
{
    public interface IOffices
    {
        Task<IEnumerable<Office>> GetOffices(string search = "");
        Task<IEnumerable<Printer>> GetAllPrinters();
        Task<OfficeData> GetOffice(int id);
        Task<DeleteResponseModel> Delete(DeleteRequestModel deleteRequestModel);
        Task<OfficeSaveResponse> SaveOffice(OfficeData model);
    }

    public class Offices : IOffices
    {
        readonly IDbContext _dbContext;
        readonly IDisplayFormattedName _formattedName;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISiteControlReader _siteControlReader;

        public Offices(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver,
                       IDisplayFormattedName formattedName,
                       ISiteControlReader siteControlReader,
                       ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _formattedName = formattedName;
            _siteControlReader = siteControlReader;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
        }

        public async Task<IEnumerable<Office>> GetOffices(string search = "")
        {
            var culture = _preferredCultureResolver.Resolve();

            IQueryable<InprotechKaizen.Model.Cases.Office> offices = _dbContext.Set<InprotechKaizen.Model.Cases.Office>();

            if (!string.IsNullOrEmpty(search))
            {
                offices = offices.Where(_ => (DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture) ?? string.Empty).ToLower().Contains(search.ToLower()));
            }

            var filteredOffices = await offices.Select(_ => new
            {
                _.Id,
                Name = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                _.Organisation,
                CountryName = _.Country == null ? null : DbFuncs.GetTranslation(_.Country.Name, null, _.Country.NameTId, culture),
                DefaultLanguageName = _.DefaultLanguage == null ? null : DbFuncs.GetTranslation(_.DefaultLanguage.Name, null, _.DefaultLanguage.NameTId, culture)
            }).ToArrayAsync();

            return filteredOffices.Select(_ => new Office
            {
                Key = _.Id,
                Value = _.Name,
                Organisation = _.Organisation?.Formatted(),
                Country = _.CountryName,
                DefaultLanguage = _.DefaultLanguageName
            });
        }

        public async Task<IEnumerable<Printer>> GetAllPrinters()
        {
            var culture = _preferredCultureResolver.Resolve();
            return await _dbContext.Set<Device>().Where(_ => _.Type == 0).Select(_ => new Printer
            {
                Key = _.Id,
                Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture)
            }).OrderBy(_ => _.Value).ToArrayAsync();
        }

        public async Task<OfficeData> GetOffice(int id)
        {
            var culture = _preferredCultureResolver.Resolve();

            var offices = _dbContext.Set<InprotechKaizen.Model.Cases.Office>().Where(_ => _.Id == id);

            if (offices == null || !offices.Any())
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            var intern = await offices.Select(_ => new
            {
                _.Id,
                Description = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                Organization = _.OrganisationId,
                _.CountryCode,
                CountryName = _.Country == null ? null : DbFuncs.GetTranslation(_.Country.Name, null, _.Country.NameTId, culture),
                _.LanguageCode,
                DefaultLanguageName = _.DefaultLanguage == null ? null : DbFuncs.GetTranslation(_.DefaultLanguage.Name, null, _.DefaultLanguage.NameTId, culture),
                _.RegionCode,
                _.PrinterCode,
                _.UserCode,
                _.CpaCode,
                _.IrnCode,
                _.ItemNoPrefix,
                _.ItemNoFrom,
                _.ItemNoTo
            }).FirstAsync();

            var officeData = new OfficeData
            {
                Id = intern.Id,
                Description = intern.Description,
                Country = !string.IsNullOrWhiteSpace(intern.CountryCode) ? new Jurisdiction {Code = intern.CountryCode, Value = intern.CountryName} : null,
                Language = intern.LanguageCode.HasValue ? new TableCodePicklistController.TableCodePicklistItem {Key = intern.LanguageCode.Value, Value = intern.DefaultLanguageName} : null,
                UserCode = intern.UserCode,
                CpaCode = intern.CpaCode,
                IrnCode = intern.IrnCode,
                ItemNoPrefix = intern.ItemNoPrefix,
                ItemNoFrom = intern.ItemNoFrom,
                ItemNoTo = intern.ItemNoTo,
                PrinterCode = intern.PrinterCode,
                RegionCode = intern.RegionCode
            };

            if (!intern.Organization.HasValue) return officeData;
            var names = await _formattedName.For(new[] {intern.Organization.Value});
            officeData.Organization = new Name {Key = intern.Organization.Value, DisplayName = names.Get(intern.Organization.Value).Name};

            return officeData;
        }

        public async Task<DeleteResponseModel> Delete(DeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null || !deleteRequestModel.Ids.Any()) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel();

            using (var txScope = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var offices = _dbContext.Set<InprotechKaizen.Model.Cases.Office>().Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();

                foreach (var ofc in offices)
                {
                    try
                    {
                        if (_dbContext.Set<TableAttributes>().Any(_ => _.SourceTableId == (short) TableTypes.Office && _.TableCodeId == ofc.Id && _.ParentTable == "NAME"))
                        {
                            response.InUseIds.Add(ofc.Id);
                        }
                        else
                        {
                            _dbContext.Set<InprotechKaizen.Model.Cases.Office>().Remove(ofc);
                            await _dbContext.SaveChangesAsync();
                        }
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int) SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(ofc.Id);
                        }

                        _dbContext.Detach(ofc);
                    }
                }

                txScope.Complete();

                if (response.InUseIds.Any())
                {
                    response.HasError = true;
                    response.Message = ConfigurationResources.InUseErrorMessage;
                }
            }

            return response;
        }

        public async Task<OfficeSaveResponse> SaveOffice(OfficeData model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            var error = ValidateOffice(model);
            var validationErrors = error as ValidationError[] ?? error.ToArray();
            if (validationErrors.Any())
            {
                return new OfficeSaveResponse
                {
                    Errors = validationErrors
                };
            }

            using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var office = _dbContext.Set<InprotechKaizen.Model.Cases.Office>().FirstOrDefault(_ => _.Id == model.Id);
                if (office == null)
                {
                    var officeId = _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Office);
                    office = new InprotechKaizen.Model.Cases.Office(officeId, model.Description);
                    _dbContext.Set<InprotechKaizen.Model.Cases.Office>().Add(office);
                }
                else
                {
                    office.Name = model.Description;
                }

                office.CountryCode = model.Country?.Code;
                office.RegionCode = model.RegionCode;
                office.OrganisationId = model.Organization?.Key;
                office.LanguageCode = model.Language?.Key;
                office.UserCode = model.UserCode;
                office.IrnCode = model.IrnCode;
                office.CpaCode = model.CpaCode;
                office.PrinterCode = model.PrinterCode;
                office.ItemNoPrefix = model.ItemNoPrefix;
                office.ItemNoTo = model.ItemNoTo;
                office.ItemNoFrom = model.ItemNoFrom;

                await _dbContext.SaveChangesAsync();
                tcs.Complete();

                return new OfficeSaveResponse
                {
                    Id = office.Id
                };
            }
        }

        IEnumerable<ValidationError> ValidateOffice(OfficeData data)
        {
            var hasDuplicateOffice = _dbContext.Set<InprotechKaizen.Model.Cases.Office>().Any(_ => _.Name == data.Description && _.Id != data.Id);
            if (hasDuplicateOffice)
            {
                yield return ValidationErrors.SetError("description", "duplicateOffice");
            }

            if (string.IsNullOrWhiteSpace(data.ItemNoPrefix)) yield break;
            {
                var hasDuplicateItemPrefix = _dbContext.Set<InprotechKaizen.Model.Cases.Office>().Any(_ => _.ItemNoPrefix == data.ItemNoPrefix && _.Id != data.Id) ||
                                             _siteControlReader.Read<string>(SiteControls.DRAFTPREFIX) == data.ItemNoPrefix;

                if (hasDuplicateItemPrefix)
                {
                    yield return ValidationErrors.SetError("itemPrefix", "duplicateItemPrefix");
                }

                var openItemNos = _dbContext.Set<OpenItem>().Where(_ => _.OpenItemNo.StartsWith(data.ItemNoPrefix)).Select(_ => _.OpenItemNo).ToArray();
                if (openItemNos.Any(_ => Convert.ToDecimal(Regex.Replace(_, "[^0-9]", string.Empty)) >= data.ItemNoTo))
                {
                    yield return ValidationErrors.SetError("itemTo", "duplicateItemNo");
                }
            }
        }
    }

    public class Printer
    {
        public int Key { get; set; }
        public string Value { get; set; }
    }

    public class OfficeData
    {
        public int? Id { get; set; }
        public string Description { get; set; }
        public Name Organization { get; set; }
        public Jurisdiction Country { get; set; }
        public TableCodePicklistController.TableCodePicklistItem Language { get; set; }

        public string UserCode { get; set; }
        public string CpaCode { get; set; }
        public string IrnCode { get; set; }
        public string ItemNoPrefix { get; set; }
        public decimal? ItemNoFrom { get; set; }
        public decimal? ItemNoTo { get; set; }
        public int? RegionCode { get; set; }
        public int? PrinterCode { get; set; }
    }

    public class OfficeSaveResponse
    {
        public IEnumerable<ValidationError> Errors { get; set; }
        public int? Id { get; set; }
    }
}