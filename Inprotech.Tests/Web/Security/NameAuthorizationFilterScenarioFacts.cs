using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.ExternalApplications.Crm;
using Inprotech.Tests.Server;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Configuration.Rules.ScreenDesigner.Cases;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Picklists;
using Inprotech.Web.Policing;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class NameAuthorizationFilterScenarioFacts
    {
        [Fact]
        public void ShouldExistsOnNameRelatedApiControllers()
        {
            var exclusions = new Dictionary<MethodInfo, string>
            {
                {typeof(CrmController).GetMethod(nameof(CrmController.UpdateResponse)), "ApiKey logic enclosed, needs further review"},
                {typeof(CrmController).GetMethod(nameof(CrmController.UpdateCorrespondence)), "ApiKey logic enclosed, needs further review"},
                {typeof(CrmController).GetMethod(nameof(CrmController.UpdateNameAttributes)), "ApiKey logic enclosed, needs further review"},
                {typeof(CrmController).GetMethod(nameof(CrmController.ListAttributes)), "ApiKey logic enclosed, needs further review"},
                {typeof(CrmController).GetMethod(nameof(CrmController.ListContacts)), "ApiKey logic enclosed, needs further review"},
                {typeof(CrmController).GetMethod(nameof(CrmController.RemoveContact)), "ApiKey logic enclosed, needs further review"},
                {typeof(CrmController).GetMethod(nameof(CrmController.AddContact)), "ApiKey logic enclosed, needs further review"},
                {typeof(CrmController).GetMethod(nameof(CrmController.CreateNewContact)), "ApiKey logic enclosed, needs further review"},
                {typeof(CrmController).GetMethod(nameof(CrmController.AddContactActivity)), "ApiKey logic enclosed, needs further review"},
                {typeof(PolicingRequestController).GetMethod(nameof(PolicingRequestController.Update)), "Administrative functions do not have name authorizations"},
                {typeof(PolicingRequestController).GetMethod(nameof(PolicingRequestController.SaveRequest)), "Administrative functions do not have name authorizations"},
                {typeof(WorkflowCharacteristicsController).GetMethod(nameof(WorkflowCharacteristicsController.GetOffice)), "Administrative functions do not have name authorizations"},
                {typeof(WorkflowEventControlController).GetMethod(nameof(WorkflowEventControlController.UpdateEventControl)), "Administrative functions do not have name authorizations"},
                {typeof(CaseScreenDesignerSearchController).GetMethod(nameof(CaseScreenDesignerSearchController.GetOffice)), "Administrative functions do not have name authorizations"},
                {typeof(CasesPicklistController).GetMethod(nameof(CasesPicklistController.Cases)), "Cases picklist results are filtered internally and is row access aware"},
                {typeof(TimePostingController).GetMethod(nameof(TimePostingController.PostForAllStaff)), "Function security handled inside function"}
            };

            foreach (var c in AllRegisteredControllers.Get())
            {
                foreach (var m in c.GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.DeclaredOnly).Except(exclusions.Keys))
                {
                    var attr = m.GetCustomAttribute<RequiresNameAuthorizationAttribute>();
                    if (attr != null) continue;

                    var warnings = new List<string>();

                    foreach (var parameter in m.GetParameters())
                    {
                        if (!parameter.ParameterType.IsComplexType())
                        {
                            if (RequiresNameAuthorizationAttribute.CommonPropertyNames.Contains(parameter.Name))
                            {
                                warnings.Add($"   {parameter.Name}");
                            }

                            continue;
                        }

                        if (parameter.ParameterType.IsXml())
                        {
                            // not supported, stackoverflow risk
                            continue;
                        }

                        TraverseDown(parameter.ParameterType, parameter.Name, warnings);
                    }

                    Assert.False(warnings.Any(), $"Should {c}.{m.Name} have a RequiresNameAuthorizationAttribute?{Environment.NewLine}{string.Join(Environment.NewLine, warnings)}");
                }
            }

            void TraverseDown(Type thisLevel, string path, List<string> all)
            {
                var properties = thisLevel.GetProperties(BindingFlags.Instance | BindingFlags.Public);
                foreach (var property in properties)
                {
                    if (property.PropertyType.IsArray || property.PropertyType.IsEnumerableOfT())
                    {
                        // Enumerable or array type not yet supported.
                        continue;
                    }

                    var thisPath = $"{path}.{property.Name}";

                    // stackoverflow may occur
                    var stackOverflowGuard = thisPath.Split('.');
                    if (stackOverflowGuard.Length - stackOverflowGuard.Distinct().Count() > 3)
                    {
                        continue;
                    }

                    if (!property.PropertyType.IsComplexType())
                    {
                        if (RequiresNameAuthorizationAttribute.CommonPropertyNames.Contains(property.Name))
                        {
                            all.Add($"   {thisPath}");
                        }

                        continue;
                    }

                    TraverseDown(property.PropertyType, thisPath, all);
                }
            }
        }

        [Fact]
        public void ShouldReferToCorrectParameters()
        {
            foreach (var c in AllRegisteredControllers.Get())
            {
                foreach (var m in c.GetMethods(BindingFlags.Instance | BindingFlags.Public))
                {
                    var attr = m.GetCustomAttribute<RequiresNameAuthorizationAttribute>();
                    if (attr == null) continue;

                    Assert.False(attr.HasPropertyName() && attr.HasPropertyPath(), $"controller {c}, action {m.Name} has invalid RequiresNameAuthorization configuration.");

                    var allPropertyNames = m.GetParameters().Select(_ => _.Name);
                    if (attr.IsDefault())
                    {
                        Assert.True(allPropertyNames.Any(_ => RequiresNameAuthorizationAttribute.CommonPropertyNames.Contains(_)),
                                    $"controller {c}, action {m.Name} does not have any of '{string.Join(",", RequiresNameAuthorizationAttribute.CommonPropertyNames)}'.");
                    }
                    else if (attr.HasPropertyName())
                    {
                        Assert.True(allPropertyNames.Contains(attr.PropertyName),
                                    $"controller {c}, action {m.Name} does not have the property {attr.PropertyName}.");
                    }
                    else
                    {
                        Assert.True(attr.PropertyPath.Contains("."), $"controller {c}, action {m.Name} has invalid RequiresNameAuthorization configuration.");

                        var propertyQueue = new Queue<string>(attr.PropertyPath.Split('.'));
                        var topLevelArg = propertyQueue.Dequeue();

                        Assert.True(allPropertyNames.Contains(topLevelArg), $"controller {c}, action {m.Name} does not have property {topLevelArg}.");

                        var currentParameterInfo = m.GetParameters().First(_ => _.Name == topLevelArg);
                        var type = currentParameterInfo.ParameterType;
                        var current = $"{topLevelArg}";
                        while (propertyQueue.Any())
                        {
                            var propertyName = propertyQueue.Dequeue();
                            current += $".{propertyName}";

                            var property = type.GetProperty(propertyName);

                            Assert.True(property?.Name == propertyName, $"controller {c}, action {m.Name} does not have property path {current}");
                            type = property.PropertyType;
                        }
                    }
                }
            }
        }
    }

    public static class RequireNameAuthorizationAttributeExtension
    {
        public static bool IsDefault(this RequiresNameAuthorizationAttribute attribute)
        {
            return !attribute.HasPropertyName() && string.IsNullOrWhiteSpace(attribute.PropertyPath);
        }

        public static bool HasPropertyName(this RequiresNameAuthorizationAttribute attribute)
        {
            return !string.IsNullOrWhiteSpace(attribute.PropertyName);
        }

        public static bool HasPropertyPath(this RequiresNameAuthorizationAttribute attribute)
        {
            return !string.IsNullOrWhiteSpace(attribute.PropertyPath);
        }
    }
}