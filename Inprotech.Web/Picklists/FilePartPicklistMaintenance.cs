using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    public interface IFilePartPicklistMaintenance
    {
        dynamic Save(FilePartPicklistItem saveDetails);
        dynamic Delete(int filePartId);
        dynamic Update(short id, FilePartPicklistItem saveDetails);
        dynamic Search(CommonQueryParameters queryParameters = null, string search = "", int caseId = 0);
        dynamic GetFile(short id, int caseId);

    }
    public class FilePartPicklistMaintenance : IFilePartPicklistMaintenance
    {
        readonly IDbContext _dbContext;
        public FilePartPicklistMaintenance(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }
        public dynamic Delete(int filePartId)
        {
            try
            {
                using (var tcs = _dbContext.BeginTransaction())
                {

                    var model = _dbContext
                        .Set<CaseFilePart>()
                        .Single(_ => _.FilePart == filePartId);

                    _dbContext.Set<CaseFilePart>().Remove(model);

                    _dbContext.SaveChanges();
                    tcs.Complete();
                }

                return new
                {
                    Result = "success"
                };
            }
            catch (Exception ex)
            {
                if (!ex.IsForeignKeyConstraintViolation())
                    throw;

                return KnownSqlErrors.CannotDelete.AsHandled();
            }
        }

        public dynamic GetFile(short id, int caseId)
        {
            var filePart = _dbContext.Set<CaseFilePart>()
                                              .SingleOrDefault(_ => _.CaseId == caseId && _.FilePart == id);
            if (filePart == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var result = new FilePartPicklistItem
            {
                Key = filePart.FilePart,
                Value = filePart.FilePartTitle,
                CaseId = filePart.CaseId
            };

            return result;
        }

        public dynamic Save(FilePartPicklistItem saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException("queryGroup");
            var validationErrors = Validate(saveDetails, Operation.Add).ToArray();

            if (!validationErrors.Any())
            {
                var lastFilePartId = 0;
                using (var tcs = _dbContext.BeginTransaction())
                {
                    if (_dbContext.Set<CaseFilePart>().ToList().Any())
                    {
                        var fileIdList = from record in _dbContext.Set<CaseFilePart>().OrderBy(_ => _.FilePart) select record.FilePart;
                        lastFilePartId = fileIdList.ToList().Last();
                    }
                    var model =
                        _dbContext.Set<CaseFilePart>()
                                    .Add(new CaseFilePart(saveDetails.CaseId)
                                    {
                                        FilePart = Convert.ToInt16(lastFilePartId + 1),
                                        FilePartTitle = saveDetails.Value
                                    });

                    _dbContext.SaveChanges();
                    tcs.Complete();

                    return new
                    {
                        Result = "success",
                        Key = model.FilePart
                    };
                }
            }
            return validationErrors.AsErrorResponse();
        }

        public dynamic Search(CommonQueryParameters queryParameters = null, string search = "", int caseId = 0)
        {
            var results = from part in _dbContext.Set<CaseFilePart>().Where(x => x.CaseId == caseId)
                          select new
                          {
                              part.FilePart,
                              Name = part.FilePartTitle,
                              part.CaseId
                          };

            if (!string.IsNullOrEmpty(search))
                results = results.Where(_ => _.Name.Contains(search));

            results = results.OrderBy(_ => _.Name);

            return Helpers.GetPagedResults(results.Select(_ => new FilePartPicklistItem
            {
                Key = _.FilePart,
                Value = _.Name,
                CaseId = _.CaseId
            }),
                                           queryParameters,
                                           null, x => x.Value, search);
        }

        public dynamic Update(short id, FilePartPicklistItem saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException("queryGroup");
            var validationErrors = Validate(saveDetails, Operation.Add).ToArray();

            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = _dbContext.Set<CaseFilePart>().Single(_ => _.FilePart == id);
                    model.FilePartTitle = saveDetails.Value;
                    _dbContext.SaveChanges();
                    tcs.Complete();

                    return new
                    {
                        Result = "success",
                        Key = model.CaseId
                    };
                }
            }
            return validationErrors.AsErrorResponse();
        }

        IEnumerable<ValidationError> Validate(FilePartPicklistItem request, Operation operation)
        {
            var all = _dbContext.Set<CaseFilePart>().Where(_ => _.CaseId == request.CaseId).ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.FilePart != request.Key))
            {
                throw new ArgumentException("Unable to retrieve file part name for update.");
            }

            foreach (var validationError in CommonValidations.Validate(request))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.FilePart != request.Key).ToArray() : all;

            if (others.Any(_ => _.FilePartTitle.IgnoreCaseEquals(request.Value)))
            {
                yield return ValidationErrors.NotUnique("value");
            }
        }
    }
}

public class FilePartPicklistItem
{
    public short? Key { get; set; }
    public string Value { get; set; }
    public int CaseId { get; set; }
}