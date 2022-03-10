using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.Items;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    public interface ITagsPicklistMaintenance
    {
        dynamic Save(Tags tags);
        dynamic Update(Tags tags);
        dynamic Delete(int id, bool confirm);

        dynamic UpdateConfirm(Tags tags);
    }

    public class TagsPicklistMaintenance : ITagsPicklistMaintenance
    {
        readonly IDbContext _dbContext;

        public TagsPicklistMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
        }

        public dynamic Save(Tags tags)
        {
            if (tags == null) throw new ArgumentNullException(nameof(tags));

            var validationErrors = Validate(tags).ToArray();
            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = _dbContext.Set<Tag>()
                                    .Add(new Tag { TagName = tags.TagName });

                    model.TagName = tags.TagName;
                    _dbContext.SaveChanges();
                    tcs.Complete();

                    return new
                    {
                        Result = "success",
                        Key = model.Id
                    };
                }
            }

            return validationErrors.AsErrorResponse();
        }

        public dynamic Update(Tags tags)
        {
            if (tags == null) throw new ArgumentNullException(nameof(tags));

            if (!_dbContext.Set<Tag>().Any(_ => _.Id != tags.Id && _.TagName == tags.TagName))
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = _dbContext.Set<Tag>()
                                          .Single(_ => _.Id == tags.Id);
                    model.TagName = tags.TagName;
                    _dbContext.SaveChanges();
                    tcs.Complete();

                    return new
                    {
                        Result = "success",
                        Key = model.Id
                    };
                }
            }

            return new
            {
                Result = "confirmation"
            };
        }

        public dynamic UpdateConfirm(Tags tags)
        {
            if (tags == null) throw new ArgumentNullException(nameof(tags));

            var tagsToBeUpdated = _dbContext.Set<Tag>().SingleOrDefault(t => t.TagName == tags.TagName);
            if (tagsToBeUpdated == null) throw new ArgumentNullException(nameof(tagsToBeUpdated));

            var siteControls = _dbContext.Set<SiteControl>().Where(_ => _.Tags.Any(t => t.Id == tags.Id)).ToList();
            if (siteControls == null) throw new ArgumentNullException(nameof(siteControls));

            using (var tcs = _dbContext.BeginTransaction())
            {
                foreach (var siteControl in siteControls)
                {
                    siteControl.Tags.Remove(siteControl.Tags.Single(_ => _.Id == tags.Id));
                    siteControl.Tags.Add(tagsToBeUpdated);
                }

                var tagsToBeDeleted = _dbContext
                    .Set<Tag>()
                    .Single(_ => _.Id == tags.Id);

                if (tagsToBeDeleted == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.TagDoesNotExist.ToString());
                _dbContext.Set<Tag>().Remove(tagsToBeDeleted);

                _dbContext.SaveChanges();
                tcs.Complete();
            }

            return new
            {
                Result = "success",
                Key = tagsToBeUpdated.Id
            };
        }

        public dynamic Delete(int id, bool confirm)
        {
            try
            {
                var entry = _dbContext.Set<Tag>().SingleOrDefault(_ => _.Id == id);

                if (entry == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.TagDoesNotExist.ToString());

                if (!confirm && entry != null)
                {
                    int count = _dbContext.Set<SiteControl>().Count(_ => _.Tags.Any(t => t.Id == entry.Id));
                    int configCount = _dbContext.Set<ConfigurationItem>().Count(_ => _.Tags.Any(t => t.Id == entry.Id));

                    if (count > 0 || configCount > 0)
                    {
                        var msg = count > 0 ? (configCount > 0 ? $"{count} site control(s) and {configCount} configuration(s)" : $"{count} site control(s)") : $"{configCount} configuration(s)";
                        return new
                        {
                            Message = $" Tag '{entry.TagName}' is being used in {msg}. If you choose to delete the tag, it will be automatically removed from the {(count > 0 ? configCount > 0 ? "site control(s) and configuration(s)" : "site control(s)" : "configuration(s)")}.<br><br> Are you sure you want to delete the tag?",
                            Result = "confirmation"
                        };
                    }
                }

                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = _dbContext
                        .Set<Tag>()
                        .Single(_ => _.Id == id);
                    if (model == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.TagDoesNotExist.ToString());
                    _dbContext.Set<Tag>().Remove(model);

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

        IEnumerable<ValidationError> Validate(Tags tags)
        {
            var all = _dbContext.Set<Tag>().ToArray();

            foreach (var validationError in CommonValidations.Validate(tags))
                yield return validationError;

            if (all.Any(_ => _.TagName.IgnoreCaseEquals(tags.TagName)))
            {
                yield return ValidationErrors.NotUnique("tagName");
            }
        }
    }
}
