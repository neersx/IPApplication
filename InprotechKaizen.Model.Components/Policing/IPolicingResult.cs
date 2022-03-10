namespace InprotechKaizen.Model.Components.Policing
{
    public interface IPolicingResult
    {
        bool HasError { get; }
        string ErrorReason { get; }
    }
}