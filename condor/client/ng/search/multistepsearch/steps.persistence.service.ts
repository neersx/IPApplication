import { Injectable } from '@angular/core';
import * as _ from 'underscore';
import { Step, TopicData } from './ipx-step.model';

export interface IStepsPersistenceService {
    getTopicExistingViewModel(topicKey: string): TopicData;
    getTopicsDefaultViewModel(topicKey: string): TopicData;
    applyStepData(topics, steps: Array<Step>): void;
}

@Injectable()
export class StepsPersistenceService implements IStepsPersistenceService {
    defaultTopicsData: Array<TopicData>;
    steps: Array<Step>;

    private readonly getSelectedStep = (steps): Step => {
        const getSelectedStep = _.first(
            _.filter(steps, (step: any) => {
                return step.selected === true;
            })
        );

        return getSelectedStep;
    };

    private readonly setTopicData = (topics): Array<TopicData> => {
        const topicsData = [];
        _.each(topics, (topic: any) => {
            topicsData.push({
                topicKey: topic.key,
                formData: topic.formData,
                filterData: topic.getFilterCriteria()
            });
        });

        return topicsData;
    };

    applyStepData = (topics, steps: Array<Step>): void => {
        const selectedStep = this.getSelectedStep(steps);
        if (selectedStep) {
            selectedStep.topicsData = this.setTopicData(topics);
        }
    };

    setFilterCriteriaForAllTopics = (topics, steps: Array<Step>): void => {
        _.each(steps, (step) => {
            _.each(topics, (topic: any) => {
                const relevantTopicData = _.first(_.filter(step.topicsData, (topicData: TopicData) => {
                    return topicData.topicKey === topic.key;
                }));
                relevantTopicData.filterData = topic.getFilterCriteria(relevantTopicData.formData);
            });
        });
    };

    getStepTopicData = (steps, stepId): Array<TopicData> => {
        const relevantStep = _.first(
            _.filter(steps, (step: any) => {
                return step.id === stepId;
            })
        );

        if (!relevantStep) {
            return [];
        }

        return relevantStep ? relevantStep.topicsData : [];
    };

    getTopicsDefaultViewModel = (topicKey: string): TopicData => {
        const topicData = _.first(
            _.filter(this.defaultTopicsData, (data: any) => {
                return data.topicKey === topicKey;
            })
        );

        return { ...topicData.formData };
    };

    getTopicExistingViewModel = (topicKey: string): TopicData => {
        if (!_.any(this.steps)) {
            return this.getTopicsDefaultViewModel(topicKey);
        }
        const topicData = _.first(
            _.filter(this.getSelectedStep(this.steps).topicsData, (stepTopicData: any) => {
                return stepTopicData.topicKey === topicKey;
            })
        );

        return topicData.formData;
    };

}