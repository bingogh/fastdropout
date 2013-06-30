addpath(genpath('binaryLRloss'));
addpath(genpath('softmaxLoss'));
addpath(genpath('utils'));

% example or 20newsbydate conll
[Xtrain, ytrain, Xtest, ytest] = getData('conll');
D = size(Xtrain,2);
K = size(ytrain,2);

%%
w_init = 0.01*randn(D*K,1);
mfOptions.Method = 'lbfgs';
mfOptions.optTol = 2e-3;
mfOptions.progTol = 2e-6;
mfOptions.LS = 2;
mfOptions.LS_init = 2;
mfOptions.MaxIter = 250;
mfOptions.DerivativeCheck = 'off';
testresults = containers.Map;
trainresults = containers.Map;
casenames = {'LROnevall', 'LROnevallDelta', 'SoftmaxDelta', 'Softmax'};
% casenames = {'LROnevallDelta','SoftmaxDelta', 'Softmax'};
for casenum = 1:length(casenames)
    obj = casenames{casenum};
    switch obj
        case 'LROnevall'
            funObj = @(w)LogisticOnevsAllLoss(w,Xtrain,ytrain);
            lambdaL2=0.01; 
            
        case 'LROnevallDelta'
            funObj = @(w)LogisticOnevsAllLossDetObjDropoutDelta(w,Xtrain,ytrain,0.5);
            lambdaL2=0.01;
            
        case 'SoftmaxDelta'
            funObj = @(w)SoftmaxLossDetObjDropoutDelta(w,Xtrain,ytrain,0.5);
            lambdaL2=0.01;
            
        case 'SoftmaxDeltaCheck'
            funObj = @(w)SoftmaxLossDetObjDropoutDeltaGradTest(w,Xtrain,ytrain,0.5);
            lambdaL2=0.01;
            
        case 'Softmax'
            funObj = @(w)SoftmaxLossFast(w,Xtrain,ytrain);
            lambdaL2=0.1;
            
        end
    
    funObjL2 = @(w)penalizedL2(w,funObj,lambdaL2);
    W = minFunc(funObjL2,w_init,mfOptions);
    W = reshape(W, D, K);
    
    resultname = [casenames{casenum}];
    
    ypredsoft = Xtest * W;
    [~, ypred] = max(ypredsoft, [], 2);
    acc = sum(ypred==oneofktoscalar(ytest)) / size(ytest,1);
    testresults(resultname) = mean(acc);

    ypredsoft = Xtrain * W;
    [~, ypred] = max(ypredsoft, [], 2);
    acc = sum(ypred == oneofktoscalar(ytrain) ) / size(ytrain,1);
    trainresults(resultname) = mean(acc);
end

keys = testresults.keys;
for i=1:length(keys)
    fprintf('%s: train=%f test=%f\n', keys{i}, trainresults(keys{i}), testresults(keys{i}));
end
