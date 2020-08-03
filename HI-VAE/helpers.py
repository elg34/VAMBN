import tensorflow as tf
import graph_new
import parser_arguments
import read_functions
import os
import numpy as np
import pandas as pd
import matplotlib
from matplotlib import pyplot as plt
import time
import re

def merge_dat(lis):
    'merge all dataframes in a list on SUBJID'
    df = lis[0]
    for x in lis[1:]:
        df=pd.merge(df, x, on = 'SUBJID')
    return df

def print_loss(epoch, start_time, avg_loss, avg_test_loglik, avg_KL_s, avg_KL_z):
    'for network training output'
    print("Epoch: [%2d]  time: %4.4f, train_loglik: %.8f, KL_z: %.8f, KL_s: %.8f, ELBO: %.8f, Test_loglik: %.8f"
          % (epoch, time.time() - start_time, avg_loss, avg_KL_z, avg_KL_s, avg_loss-avg_KL_z-avg_KL_s, avg_test_loglik))
    
def train_network(settings):
    'run training (no output)'

    argvals = settings.split()
    args = parser_arguments.getArgs(argvals)
    print(args)

    #Create a directoy for the save file
    if not os.path.exists('./Saved_Networks/' + args.save_file):
        os.makedirs('./Saved_Networks/' + args.save_file)
    network_file_name='./Saved_Networks/' + args.save_file + '/' + args.save_file +'.ckpt'
    load_file_name='./Saved_Networks/' + re.sub('_BNet','',args.save_file) + '/' + re.sub('_BNet','',args.save_file) +'.ckpt'
    log_file_name='./Saved_Network/' + args.save_file + '/log_file_' + args.save_file +'.txt'

    #Creating graph
    sess_HVAE = tf.Graph()

    with sess_HVAE.as_default():
        tf_nodes = graph_new.HVAE_graph(args.model_name, args.types_file, args.batch_size,
                                    learning_rate=args.learning_rate, z_dim=args.dim_latent_z, y_dim=args.dim_latent_y, s_dim=args.dim_latent_s, y_dim_partition=args.dim_latent_y_partition)

    ################### Running the VAE Training #################################
    train_data, types_dict, miss_mask, true_miss_mask, n_samples = read_functions.read_data(args.data_file, args.types_file, args.miss_file, args.true_miss_file)
    n_batches = int(np.floor(np.shape(train_data)[0]/args.batch_size))#Get an integer number of batches
    miss_mask = np.multiply(miss_mask, true_miss_mask)#Compute the real miss_mask

    with tf.Session(graph=sess_HVAE) as session:
        # Add ops to save and restore all the variables.
        saver = tf.train.Saver()
        if args.restore==1:
            saver.restore(session, load_file_name)
            print("Model restored: "+load_file_name)
        else:
            print('Initizalizing Variables ...')
            tf.global_variables_initializer().run()

        start_time = time.time()
        # Training cycle
        loglik_epoch = []
        testloglik_epoch = []
        KL_s_epoch = []
        KL_z_epoch = []
        loss_epoch=[]
        for epoch in range(args.epochs):
            avg_loss = 0.
            avg_loss_reg = 0.
            avg_KL_s = 0.
            avg_KL_z = 0.
            samples_list = []
            p_params_list = []
            q_params_list = []
            log_p_x_total = []
            log_p_x_missing_total = []

            # Annealing of Gumbel-Softmax parameter
            tau = np.max([1.0 - (0.999/(args.epochs-50))*epoch,1e-3])
            print(tau)

            #Randomize the data in the mini-batches
            random_perm = np.random.permutation(range(np.shape(train_data)[0]))
            train_data_aux = train_data[random_perm,:]
            miss_mask_aux = miss_mask[random_perm,:]
            true_miss_mask_aux = true_miss_mask[random_perm,:]

            for i in range(n_batches):
                data_list, miss_list = read_functions.next_batch(train_data_aux, types_dict, miss_mask_aux, args.batch_size, index_batch=i) #Create inputs for the feed_dict
                data_list_observed = [data_list[i]*np.reshape(miss_list[:,i],[args.batch_size,1]) for i in range(len(data_list))] #Delete not known data (input zeros)

                #Create feed dictionary
                feedDict = {i: d for i, d in zip(tf_nodes['ground_batch'], data_list)}
                feedDict.update({i: d for i, d in zip(tf_nodes['ground_batch_observed'], data_list_observed)})
                feedDict[tf_nodes['miss_list']] = miss_list 
                feedDict[tf_nodes['miss_list_VP']] = np.ones(miss_list.shape) # only works when running all 1 batch 1 epoch
                feedDict[tf_nodes['tau_GS']] = tau
                feedDict[tf_nodes['zcodes']] = np.ones(args.batch_size).reshape((args.batch_size,1)) # just for placeholder
                feedDict[tf_nodes['scodes']] = np.ones(args.batch_size).reshape((args.batch_size,1)) # just for placeholder

                #Running VAE
                _,loss,KL_z,KL_s,samples,log_p_x,log_p_x_missing,p_params,q_params,loss_reg  = session.run([tf_nodes['optim'], tf_nodes['loss_re'], tf_nodes['KL_z'], tf_nodes['KL_s'], tf_nodes['samples'],
                                                         tf_nodes['log_p_x'], tf_nodes['log_p_x_missing'],tf_nodes['p_params'],tf_nodes['q_params'],tf_nodes['loss_reg']],
                                                         feed_dict=feedDict)

                #Collect all samples, distirbution parameters and logliks in lists
                samples_list.append(samples)
                p_params_list.append(p_params)
                q_params_list.append(q_params)
                log_p_x_total.append(log_p_x)
                log_p_x_missing_total.append(log_p_x_missing)

                # Compute average loss
                avg_loss += np.mean(loss)
                avg_KL_s += np.mean(KL_s)
                avg_KL_z += np.mean(KL_z)
                avg_loss_reg+=np.mean(loss_reg)

            print('Epoch: '+str(epoch)+' Rec. Loss: '+str(avg_loss/n_batches)+' KL s: '+str(avg_KL_s/n_batches)+' KL z: '+str(avg_KL_z/n_batches))
            loss_epoch.append(-avg_loss/n_batches)

            if epoch % args.save == 0:
                print('Saving Variables ... '+network_file_name)  
                save_path = saver.save(session, network_file_name)    

        print('Training Finished ...')
        plt.clf()
        plt.figure()
        plt.plot(loss_epoch)
        plt.xlabel('Epoch')
        plt.ylabel('Reconstruction loss')  # we already handled the x-label with ax1
        plt.title(args.save_file)
        plt.savefig('Saved_Networks/train_stats/'+args.save_file+'.png', bbox_inches='tight')
    
def enc_network(settings):
    'get s and z samples as embeddings as well as the original dataframe (with relevelled factors & NA\'s=0!)'
    argvals = settings.split()
    args = parser_arguments.getArgs(argvals)
    print(args)

    #Create a directoy for the save file
    if not os.path.exists('./Saved_Networks/' + args.save_file):
        os.makedirs('./Saved_Networks/' + args.save_file)
    network_file_name='./Saved_Networks/' + args.save_file + '/' + args.save_file +'.ckpt'
    log_file_name='./Saved_Network/' + args.save_file + '/log_file_' + args.save_file +'.txt'

    #Creating graph
    sess_HVAE = tf.Graph()

    with sess_HVAE.as_default():
        tf_nodes = graph_new.HVAE_graph(args.model_name, args.types_file, args.batch_size,
                                    learning_rate=args.learning_rate, z_dim=args.dim_latent_z, y_dim=args.dim_latent_y, s_dim=args.dim_latent_s, y_dim_partition=args.dim_latent_y_partition)

    train_data, types_dict, miss_mask, true_miss_mask, n_samples = read_functions.read_data(args.data_file, args.types_file, args.miss_file, args.true_miss_file)
    #Get an integer number of batches
    n_batches = int(np.floor(np.shape(train_data)[0]/args.batch_size))
    #Compute the real miss_mask
    miss_mask = np.multiply(miss_mask, true_miss_mask)

    with tf.Session(graph=sess_HVAE) as session:
        # Add ops to save and restore all the variables.
        saver = tf.train.Saver()
        saver.restore(session, network_file_name)
        print("Model restored: "+network_file_name)

        start_time = time.time()

        # Training cycle
        loglik_epoch = []
        testloglik_epoch = []
        epoch=0
        avg_loss = 0.
        avg_loss_reg = 0.
        avg_KL_s = 0.
        avg_KL_y = 0.
        avg_KL_z = 0.
        samples_list = []
        samples_list_test = []
        p_params_list = []
        q_params_list = []
        log_p_x_total = []
        log_p_x_missing_total = []

        # Constant Gumbel-Softmax parameter (where we have finished the annealing)
        tau = 1e-3

        for i in range(n_batches):      

            data_list, miss_list = read_functions.next_batch(train_data, types_dict, miss_mask, args.batch_size, index_batch=i)#Create train minibatch
            data_list_observed = [data_list[i]*np.reshape(miss_list[:,i],[args.batch_size,1]) for i in range(len(data_list))]#Delete not known data

            #Create feed dictionary
            feedDict = {i: d for i, d in zip(tf_nodes['ground_batch'], data_list)}
            feedDict.update({i: d for i, d in zip(tf_nodes['ground_batch_observed'], data_list_observed)})
            feedDict[tf_nodes['miss_list']] = miss_list
            feedDict[tf_nodes['miss_list_VP']] = np.ones(miss_list.shape) # unused
            feedDict[tf_nodes['tau_GS']] = tau
            feedDict[tf_nodes['zcodes']] = np.ones(args.batch_size).reshape((args.batch_size,1))
            feedDict[tf_nodes['scodes']] = np.ones(args.batch_size).reshape((args.batch_size,1))

            #Get samples from the model
            KL_s,loss,samples,log_p_x,log_p_x_missing,loss_total,KL_z,p_params,q_params,loss_reg  = session.run([tf_nodes['KL_s'], tf_nodes['loss_re'],tf_nodes['samples'],
                                                    tf_nodes['log_p_x'],
                                                     tf_nodes['log_p_x_missing'],tf_nodes['loss'],
                                                     tf_nodes['KL_z'],tf_nodes['p_params'],tf_nodes['q_params'],tf_nodes['loss_reg']],
                                                     feed_dict=feedDict)

            samples_list.append(samples)
            q_params_list.append(q_params)

            # Compute average loss
            avg_loss += np.mean(loss)
            avg_loss_reg += np.mean(loss_reg)
            avg_KL_s += np.mean(KL_s)
            avg_KL_z += np.mean(KL_z)

        #Transform discrete variables to original values (this is for getting the original data frame)
        train_data_transformed = read_functions.discrete_variables_transformation(train_data, types_dict)

        #Create global dictionary of the distribution parameters
        q_params_complete = read_functions.q_distribution_params_concatenation(q_params_list,  args.dim_latent_z, args.dim_latent_s)

        # return the deterministic and sampled s and z codes and the reconstructed dataframe (now imputed)
        encs=np.argmax(q_params_complete['s'],1)
        encz=q_params_complete['z'][0,:,:]
        return [encs,encz,train_data_transformed]
        
def dec_network(settings,zcodes,scodes,VP=False):
    'decode using set s and z values (if generated provide a generated miss_list) and return decoded data'
    argvals = settings.split()
    args = parser_arguments.getArgs(argvals)
    print(args)

    #Create a directoy for the save file
    if not os.path.exists('./Saved_Networks/' + args.save_file):
        os.makedirs('./Saved_Networks/' + args.save_file)
    network_file_name='./Saved_Networks/' + args.save_file + '/' + args.save_file +'.ckpt'
    log_file_name='./Saved_Network/' + args.save_file + '/log_file_' + args.save_file +'.txt'
    
    #Creating graph
    sess_HVAE = tf.Graph()
    with sess_HVAE.as_default():
        tf_nodes = graph_new.HVAE_graph(args.model_name, args.types_file, args.batch_size,
                                    learning_rate=args.learning_rate, z_dim=args.dim_latent_z, y_dim=args.dim_latent_y, s_dim=args.dim_latent_s, y_dim_partition=args.dim_latent_y_partition)

    train_data, types_dict, miss_mask, true_miss_mask, n_samples = read_functions.read_data(args.data_file, args.types_file, args.miss_file, args.true_miss_file)
    
    #Get an integer number of batches
    n_batches = int(np.floor(np.shape(train_data)[0]/args.batch_size))
    
    ######Compute the real miss_mask
    miss_mask = np.multiply(miss_mask, true_miss_mask)
        
    with tf.Session(graph=sess_HVAE) as session:
        # Add ops to save and restore all the variables.
        saver = tf.train.Saver()
        saver.restore(session, network_file_name)
        print("Model restored: "+network_file_name)

        print('::::::DECODING:::::::::')
        start_time = time.time()
        # Training cycle
        epoch=0
        samples_list = []

        # Constant Gumbel-Softmax parameter (where we have finished the annealing)
        tau = 1e-3

        for i in range(n_batches):      

            data_list, miss_list = read_functions.next_batch(train_data, types_dict, miss_mask, args.batch_size, index_batch=i) #Create inputs for the feed_dict
            data_list_observed = [data_list[i]*np.reshape(miss_list[:,i],[args.batch_size,1]) for i in range(len(data_list))]#Delete not known data

            #Create feed dictionary
            feedDict = {i: d for i, d in zip(tf_nodes['ground_batch'], data_list)}
            feedDict.update({i: d for i, d in zip(tf_nodes['ground_batch_observed'], data_list_observed)})
            feedDict[tf_nodes['miss_list']] = miss_list
            if VP:
                vpfile='VP_misslist/'+re.sub('data_python/|.csv','',args.data_file)+'_vpmiss.csv'
                print('::::::::::::'+vpfile)
                feedDict[tf_nodes['miss_list_VP']] = pd.read_csv(vpfile,header=None)
            elif VP=='nomiss':
                print(':::::::::::: ones for miss list VP')
                feedDict[tf_nodes['miss_list_VP']] = np.ones(miss_list.shape)
            else:
                feedDict[tf_nodes['miss_list_VP']] = miss_list
            feedDict[tf_nodes['tau_GS']] = tau
            feedDict[tf_nodes['zcodes']] = np.array(zcodes).reshape((len(zcodes),1))
            feedDict[tf_nodes['scodes']] = np.array(scodes).reshape((len(scodes),1))

            #Get samples from the fixed decoder function
            samples_zgen,log_p_x_test,log_p_x_missing_test,test_params  = session.run([tf_nodes['samples_zgen'],tf_nodes['log_p_x_zgen'],tf_nodes['log_p_x_missing_zgen'],tf_nodes['test_params_zgen']],
                                                 feed_dict=feedDict)
            samples_list.append(samples_zgen)

        #Separate the samples from the batch list
        s_aux, z_aux, y_total, est_data = read_functions.samples_concatenation(samples_list)

        #Transform discrete variables to original values
        est_data_transformed = read_functions.discrete_variables_transformation(est_data, types_dict)

        return est_data_transformed

def dec_network_loglik(settings,zcodes,scodes,VP=False):
    'decode using set s and z values (if generated provide a generated miss_list) and return decoded data'
    argvals = settings.split()
    args = parser_arguments.getArgs(argvals)
    print(args)

    #Create a directoy for the save file
    if not os.path.exists('./Saved_Networks/' + args.save_file):
        os.makedirs('./Saved_Networks/' + args.save_file)
    network_file_name='./Saved_Networks/' + args.save_file + '/' + args.save_file +'.ckpt'
    log_file_name='./Saved_Network/' + args.save_file + '/log_file_' + args.save_file +'.txt'
    
    #Creating graph
    sess_HVAE = tf.Graph()
    with sess_HVAE.as_default():
        tf_nodes = graph_new.HVAE_graph(args.model_name, args.types_file, args.batch_size,
                                    learning_rate=args.learning_rate, z_dim=args.dim_latent_z, y_dim=args.dim_latent_y, s_dim=args.dim_latent_s, y_dim_partition=args.dim_latent_y_partition)

    train_data, types_dict, miss_mask, true_miss_mask, n_samples = read_functions.read_data(args.data_file, args.types_file, args.miss_file, args.true_miss_file)
    
    #Get an integer number of batches
    n_batches = int(np.floor(np.shape(train_data)[0]/args.batch_size))
    
    ######Compute the real miss_mask
    miss_mask = np.multiply(miss_mask, true_miss_mask)
        
    with tf.Session(graph=sess_HVAE) as session:
        # Add ops to save and restore all the variables.
        saver = tf.train.Saver()
        saver.restore(session, network_file_name)
        print("Model restored: "+network_file_name)

        print('::::::DECODING:::::::::')
        start_time = time.time()
        # Training cycle
        epoch=0
        samples_list = []

        # Constant Gumbel-Softmax parameter (where we have finished the annealing)
        tau = 1e-3

        for i in range(n_batches):      

            data_list, miss_list = read_functions.next_batch(train_data, types_dict, miss_mask, args.batch_size, index_batch=i) #Create inputs for the feed_dict
            data_list_observed = [data_list[i]*np.reshape(miss_list[:,i],[args.batch_size,1]) for i in range(len(data_list))]#Delete not known data

            #Create feed dictionary
            feedDict = {i: d for i, d in zip(tf_nodes['ground_batch'], data_list)}
            feedDict.update({i: d for i, d in zip(tf_nodes['ground_batch_observed'], data_list_observed)})
            feedDict[tf_nodes['miss_list']] = miss_list
            if VP==True:
                vpfile='VP_misslist/'+re.sub('data_python/|.csv','',args.data_file)+'_vpmiss.csv'
                print('::::::::::::'+vpfile)
                feedDict[tf_nodes['miss_list_VP']] = pd.read_csv(vpfile,header=None)
            elif VP=='nomiss':
                print(':::::::::::: ones for miss list VP')
                feedDict[tf_nodes['miss_list_VP']] = np.ones(miss_list.shape)
            else:
                feedDict[tf_nodes['miss_list_VP']] = miss_list
            feedDict[tf_nodes['tau_GS']] = tau
            feedDict[tf_nodes['zcodes']] = np.array(zcodes).reshape((len(zcodes),1))
            feedDict[tf_nodes['scodes']] = np.array(scodes).reshape((len(scodes),1))

            #Get samples from the fixed decoder function
            samples_zgen,log_p_x_test,log_p_x_missing_test,test_params  = session.run([tf_nodes['samples_zgen'],tf_nodes['log_p_x_zgen'],tf_nodes['log_p_x_missing_zgen'],tf_nodes['test_params_zgen']],
                                                 feed_dict=feedDict)
            samples_list.append(samples_zgen)

        return log_p_x_test
