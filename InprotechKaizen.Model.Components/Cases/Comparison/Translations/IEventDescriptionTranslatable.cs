namespace InprotechKaizen.Model.Components.Cases.Comparison.Translations
{
    public interface IEventDescriptionTranslatable
    {
        int? EventNo { get; }

        int? CriteriaId { get; }

        void SetTranslatedDescription(string translated);
    }
}